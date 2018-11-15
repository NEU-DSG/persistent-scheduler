# Persistent Job Scheduler

This is a wrapper application for the eXist DB scheduler module. Ordinarily, a user job scheduled through 
XQuery would be lost when the database is shut down. Instead, the app creates a catalog of XQuery user jobs 
which should be scheduled whenever eXist is running. This approach ensures that other EXPath packages can 
schedule XQuery jobs on installation, without requiring the user to edit eXist's configuration file for 
job persistence.

## Scheduling jobs

To schedule a cron job, use the function `pjs:schedule-xquery-cron-job()`, which takes most of the same
parameters as eXist's scheduler library. There is one omission: you cannot use this function to keep a 
job scheduled after it fails once. There is also one addition: you can optionally "force" a job to be 
scheduled, which will delete an existing job with the same name before rescheduling it.

## Rescheduling jobs

The PJScheduler application does not automatically reschedule the XQueries listed in its catalog. However, 
there are three rescheduling options.

To reschedule manually, the function `pjs:reschedule-xquery-jobs()` can be executed by any user with DBA 
permissions. Alternatively, the XQuery "rescheduler.xq" provides the same functionality, but can be run by 
any user, including the guest user.

To make eXist reschedule all jobs for you after restarting, add the following to EXIST_HOME/conf.xml, 
inside `/exist/scheduler`:

  <job type="user" name="persistent-scheduler" 
          xquery="/db/apps/persistent-scheduler/rescheduler.xq"
          period="5000" repeat="0" />

