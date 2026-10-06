package com.wordjourney.app;

import java.util.concurrent.Executor;

/** A single pending feedback request. Gameplay and the platform UI never wait
 * for audio calls. Stop/close invalidate old requests before the next session. */
public final class BoundedAudioQueue {
    public interface Clock { long now(); }
    public interface Player {
        void play(String name, float volume);
        void stop();
    }
    private static final class Request {
        final String name;
        final float volume;
        final long at, generation;
        Request(String name, float volume, long at, long generation) {
            this.name = name; this.volume = volume; this.at = at; this.generation = generation;
        }
    }
    private final Object lock = new Object();
    private final Executor worker;
    private final Clock clock;
    private final Player player;
    private Request pending;
    private long generation;
    private boolean posted, closed;
    public BoundedAudioQueue(Executor worker, Clock clock, Player player) {
        this.worker = worker; this.clock = clock; this.player = player;
    }
    private static int priority(String name) {
        if (name.equals("finish") || name.equals("milestone")) return 3;
        if (name.equals("combo") || name.equals("wrong")) return 2;
        return name.equals("correct") ? 1 : 0;
    }
    public void submit(String name, float volume) {
        if (volume <= 0) return;
        synchronized (lock) {
            if (closed) return;
            long now = clock.now();
            if (pending == null || priority(name) >= priority(pending.name) || now - pending.at > 180) {
                pending = new Request(name, volume, now, generation);
            }
            if (!posted) scheduleLocked();
        }
    }
    private void scheduleLocked() {
        final long token = generation;
        posted = true;
        worker.execute(() -> drain(token));
    }
    private void drain(long token) {
        Request next;
        synchronized (lock) {
            next = !closed && pending != null && pending.generation == token && token == generation ? pending : null;
            if (next != null) pending = null;
        }
        try {
            if (next != null && clock.now() - next.at <= 250) player.play(next.name, next.volume);
        } finally {
            synchronized (lock) {
                posted = false;
                if (!closed && pending != null) scheduleLocked();
            }
        }
    }
    public void stop() {
        synchronized (lock) {
            if (closed) return;
            generation++;
            pending = null;
            worker.execute(player::stop);
        }
    }
    public boolean close(Runnable cleanup) {
        synchronized (lock) {
            if (closed) return false;
            closed = true;
            generation++;
            pending = null;
            worker.execute(() -> { player.stop(); cleanup.run(); });
            return true;
        }
    }
}
