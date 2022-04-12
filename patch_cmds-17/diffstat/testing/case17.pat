--- linux/kernel/sched.c.user	2002-08-08 11:52:55.000000000 -0300
+++ linux/kernel/sched.c	2002-08-08 20:44:01.000000000 -0300
@@ -124,6 +124,9 @@
 # define finish_arch_switch(rq)		spin_unlock_irq(&(rq)->lock)
 #endif

+/* Per-user fair scheduler on/off switch. */
+int fairsched_enabled;
+
 /*
  * task_rq_lock - lock the runqueue a given task resides on and disable
  * interrupts.  Note the ordering: we can safely lookup the task_rq without
@@ -167,6 +170,44 @@
 	p->array = array;
 }

+/*
+ * Modify the per task bonus with a bonus based on the CPU usage
+ * of all the user's tasks combined.  This won't just redistribute
+ * the CPU more fairly between the users, it will also make the
+ * interactive tasks of a CPU-hogging user "feel slower", giving
+ * that user a good reason to not hog the system ;)
+ */
+static inline int peruser_bonus(int bonus, struct user_struct * user)
+{
+	int userbonus, i, max_cpu;
+
+	/*
+	 * Decay the per-user cpu usage once for every STARVATION_LIMIT
+	 * interval.  We round up the number of intervals so we won't
+	 * have to recalculate again immediately and always increment
+	 * user->cpu_lastcalc with a multiple of STARVATION_LIMIT so
+	 * we don't have different decay rates for users with different
+	 * wakeup patterns.
+	 */
+	if (time_after(jiffies, user->cpu_lastcalc + STARVATION_LIMIT)) {
+		i = ((jiffies - user->cpu_lastcalc) / STARVATION_LIMIT) + 1;
+		user->cpu_lastcalc += i * STARVATION_LIMIT;
+		user->cpu_time >>= i;
+	}
+
+	/*
+	 *   0% cpu usage -> + BONUS
+	 *  50% cpu usage -> 0
+	 * 100% cpu usage -> - BONUS
+	 */
+	max_cpu = smp_num_cpus * STARVATION_LIMIT * 3 / 4;
+
+	/**** FIXME ****/
+	userbonus = max_cpu - (user->cpu_time + 1)
+
+	return (bonus + userbonus) / 2;
+}
+
 static inline int effective_prio(task_t *p)
 {
 	int bonus, prio;
@@ -185,6 +226,9 @@
 	bonus = MAX_USER_PRIO*PRIO_BONUS_RATIO*p->sleep_avg/MAX_SLEEP_AVG/100 -
 			MAX_USER_PRIO*PRIO_BONUS_RATIO/100/2;

+	if (fairsched_enabled)
+		bonus = peruser_bonus(bonus, p->user);
+
 	prio = p->static_prio - bonus;
 	if (prio < MAX_RT_PRIO)
 		prio = MAX_RT_PRIO;
@@ -673,6 +717,9 @@
 		kstat.per_cpu_user[cpu] += user_tick;
 	kstat.per_cpu_system[cpu] += system;

+	if (fairsched_enabled && p->user)
+		p->user->cpu_time++;
+
 	/* Task might have expired already, but not scheduled off yet */
 	if (p->array != rq->active) {
 		set_tsk_need_resched(p);
--- linux/kernel/user.c.user	2002-08-08 19:30:05.000000000 -0300
+++ linux/kernel/user.c	2002-08-08 19:40:43.000000000 -0300
@@ -101,6 +101,8 @@
 		atomic_set(&new->__count, 1);
 		atomic_set(&new->processes, 0);
 		atomic_set(&new->files, 0);
+		new->cpu_time = 0;
+		new->cpu_lastcalc = jiffies;

 		/*
 		 * Before adding this, check whether we raced
--- linux/include/linux/sched.h.user	2002-08-08 11:53:28.000000000 -0300
+++ linux/include/linux/sched.h	2002-08-08 20:25:13.000000000 -0300
@@ -80,6 +80,9 @@
 extern unsigned long nr_running(void);
 extern unsigned long nr_uninterruptible(void);

+/* Per-user fair scheduler on/off switch */
+extern int fairsched_enabled;
+
 //#include <linux/fs.h>
 #include <linux/time.h>
 #include <linux/param.h>
@@ -288,6 +291,14 @@
 	atomic_t processes;	/* How many processes does this user have? */
 	atomic_t files;		/* How many open files does this user have? */

+	/*
+	 * Fair scheduler CPU usage counting. If the per-user fair scheduler
+	 * is enabled, we keep track of how much CPU time this user is using,
+	 * using a floating average.
+	 */
+	unsigned long cpu_time;
+	unsigned long cpu_lastcalc;
+
 	/* Hash table maintenance information */
 	struct user_struct *next, **pprev;
 	uid_t uid;
