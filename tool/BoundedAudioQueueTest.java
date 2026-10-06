import com.wordjourney.app.BoundedAudioQueue;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Executor;

/** Tests the production mailbox with a deterministic worker; no Android/JUnit
 * dependency and no device settings. Run with the existing javac/java. */
public final class BoundedAudioQueueTest {
    static final class Fixture implements Executor, BoundedAudioQueue.Clock, BoundedAudioQueue.Player {
        final ArrayDeque<Runnable> tasks = new ArrayDeque<>();
        final List<String> played = new ArrayList<>();
        final BoundedAudioQueue queue = new BoundedAudioQueue(this, this, this);
        long at;
        public long now() { return at; }
        public void execute(Runnable r) { tasks.add(r); }
        public void play(String name, float volume) { played.add(name + ":" + volume); }
        public void stop() { played.add("stop"); }
        void runAll() { while (!tasks.isEmpty()) tasks.remove().run(); }
    }
    static void expect(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        Fixture burst = new Fixture();
        for (int i = 0; i < 1000; i++) burst.queue.submit("select", .35f);
        burst.queue.submit("correct", .35f); burst.queue.submit("select", .35f);
        expect(burst.tasks.size() == 1); expect(burst.played.isEmpty());
        burst.runAll(); expect(burst.played.equals(Arrays.asList("correct:0.35")));
        Fixture stop = new Fixture();
        stop.queue.submit("correct", .35f); stop.queue.stop(); stop.queue.submit("select", .35f);
        stop.runAll(); expect(stop.played.equals(Arrays.asList("stop", "select:0.35")));
        Fixture expired = new Fixture();
        expired.queue.submit("correct", .35f); expired.at = 251; expired.runAll();
        expect(expired.played.isEmpty());
        Fixture milestones = new Fixture();
        milestones.queue.submit("milestone", .35f); milestones.queue.submit("select", .35f);
        milestones.queue.submit("combo", .35f); milestones.runAll();
        expect(milestones.played.equals(Arrays.asList("milestone:0.35")));
        Fixture close = new Fixture();
        close.queue.submit("correct", .35f);
        expect(close.queue.close(() -> close.played.add("release")));
        expect(!close.queue.close(() -> close.played.add("duplicate")));
        close.queue.submit("finish", .35f); close.runAll();
        expect(close.played.equals(Arrays.asList("stop", "release")));
        Fixture mute = new Fixture(); mute.queue.submit("correct", 0);
        expect(mute.tasks.isEmpty());
        System.out.println("6 native audio queue regressions passed: bounded burst, stop/new-session, expiry, priority, close, mute.");
    }
}
