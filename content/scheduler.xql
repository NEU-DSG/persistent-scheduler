xquery version "3.0";

  module namespace pjs="http://www.wwp.northeastern.edu/ns/persistent-scheduler";
  import module namespace repo="http://exist-db.org/xquery/repo";
  import module namespace sched="http://exist-db.org/xquery/scheduler";
(:  NAMESPACES  :)
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(:~
  A wrapper library for the eXist DB scheduler module. Ordinarily, a user job scheduled through XQuery 
  would be lost when the database is shut down. This library creates a catalog of XQuery user jobs which 
  should be scheduled whenever eXist is running. This approach ensures that EXPath packages can schedule
  XQuery jobs on installation, without requiring the user to edit eXist's configuration file for job 
  persistence.
  
  All functions are limited to users in the "dba" group.
  
    @author Ashley M. Clark, Northeastern University Women Writers Project
    @version 0.2.0
    @since November 9, 2018
  :)
 
(:  VARIABLES  :)
  declare %private variable $pjs:app-root :=
    let $appPath := repo:get-root()
    return 'xmldb:exist://'||$appPath||'persistent-scheduler/';
  declare %private variable $pjs:catalog := 
    let $catalogPath := $pjs:app-root||'data/catalog.xml'
    return doc($catalogPath);
  declare %private variable $pjs:log :=
    let $logPath := $pjs:app-root||'data/activity-log.xml'
    return doc($logPath);


(:  FUNCTIONS  :)

(:~
  Unschedule and delete an XQuery job from the catalog. If the job does not exist in the catalog, 
  nothing is done.
  
  @param job-name is the title given to the persistent job.
  @return empty sequence.
 :)
declare function pjs:delete-persistent-job($job-name as xs:string) {
  let $job := $pjs:catalog//job[@name eq $job-name]
  return
    if ( exists($job) ) then 
      (
        pjs:unschedule-job($job-name),
        update delete $job
        ,
        pjs:update-activity-log("Removed job from catalog", $job-name, 'info')
      )
    else ()
};

(:~
  Reschedule every XQuery job listed in the catalog. No previously-existing job will be overwritten. 
  This is most useful after eXist DB has been restarted, since all jobs scheduled via XQuery will be 
  cleared.
  
  @return empty sequence.
 :)
declare function pjs:reschedule-xquery-jobs() {
  for $job in $pjs:catalog//job
  let $xq := $job/@xquery/data(.)
  let $cron := $job/@cron
  let $name := $job/@name/data(.)
  let $params := 
    let $all := $job/parameter
    return
      if ( count($all) gt 0 ) then
        <parameters> {
          for $param in $all
          return
            <param name="{$param/@name}" value="{$param/@value}"/>
        }</parameters>
      else ()
  return
    if ( $cron ) then
      pjs:schedule-xquery-cron-job($xq, $cron/data(.), $name, $params)
    else () (: TODO: add periodic jobs :)
};

(:~
  Schedule a cron job implemented in XQuery. If a job already exists with the requested name, the task 
  will fail.
  
  @param xq-filepath is a path to the XQuery script which will be scheduled.
  @param cron-expression is the cron string representing when and for how long the job should run.
  @param job-name is the title given to the cron job. It must be unique to eXist's scheduler.
  @param job-parameters is an XML fragment containing parameter names and string values. E.g. `<parameters><param name="string" value="string"/></parameters>`
  @return empty sequence.
:)
declare function pjs:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
                                                $job-name as xs:string, $job-parameters as element()?) {
  pjs:schedule-xquery-cron-job($xq-filepath, $cron-expression, $job-name, $job-parameters, false())
};

(:~
  Schedule a cron job implemented in XQuery. If a job already exists with the requested name, the task 
  will fail unless $force is true (indicating that the job should be overwritten if necessary). This 
  function should *only* be used when the job name is guaranteed unique to the requested XQuery task.
  
  @param xq-filepath is a path to the XQuery script which will be scheduled.
  @param cron-expression is the cron string representing when and for how long the job should run.
  @param job-name is the title given to the cron job. It must be unique to eXist's scheduler.
  @param job-parameters is an XML fragment containing parameter names and string values. E.g. `<parameters><param name="string" value="string"/></parameters>`
  @param force is a boolean value. If true, a previously-scheduled job matching $job-name will be deleted before the new job is scheduled.
  @return empty sequence.
:)
declare function pjs:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
                                                $job-name as xs:string, $job-parameters as element()?, $force as xs:boolean) {
  let $previouslyScheduled := pjs:job-exists($job-name)
  let $nowScheduled :=
    if ( $previouslyScheduled and not($force) ) then
      false()
    else if ( $previouslyScheduled ) then
      (
        sched:delete-scheduled-job($job-name),
        sched:schedule-xquery-cron-job($xq-filepath, $cron-expression, $job-name, $job-parameters)
      )[2]
    else
      sched:schedule-xquery-cron-job($xq-filepath, $cron-expression, $job-name, $job-parameters)
  let $jobListing :=
    <job type="user" name="{$job-name}" xquery="{$xq-filepath}"
                cron="{$cron-expression}" >
      {
        for $param in $job-parameters//param
        return
          <parameter name="{$param/@name}" value="{$param/@value}"/>
      }
    </job>
  return
    if ( $nowScheduled ) then
      (
        pjs:update-job-in-catalog($jobListing),
        pjs:update-activity-log('Successfully scheduled job', $job-name, 'info')
      )
    else
      pjs:update-activity-log('Could not schedule job', $job-name, 'warn')
};

(:~
  Unschedule an XQuery job listed in the catalog. The job will remain in the catalog, but eXist will not 
  run it until it has been rescheduled.
  
  @param job-name is the title given to the persistent job.
  @return empty sequence.
 :)
declare function pjs:unschedule-job($job-name as xs:string) {
  if ( pjs:job-exists($job-name) ) then
    let $isUnscheduled := sched:delete-scheduled-job($job-name)
    return
      if ( $isUnscheduled ) then
        pjs:update-activity-log("Unscheduled job", $job-name, 'info')
      else 
        pjs:update-activity-log("Could not unschedule job", $job-name, 'warn')
  else ()
};


(:  FUNCTIONS, PRIVATE  :)

(: Test if a job exists in the catalog. (If it doesn't exist there, it is beyond the scope of this 
  application. :)
declare %private function pjs:job-exists($job-name) as xs:boolean {
  exists(sched:get-scheduled-jobs()//sched:job[@name eq $job-name])
};

(: Create a new log entry for (re)scheduling a job. :)
declare %private function pjs:update-activity-log($message as xs:string, $job-name as xs:string, $status as xs:string) {
  let $entry :=
    <entry status="{$status}" name="{$job-name}" when="{current-dateTime()}">
      { $message }</entry>
  return
    update insert $entry into $pjs:log/log
};

(: Create or update a scheduled job in the catalog. This should only be used when a job has been 
  successfully scheduled. :)
declare %private function pjs:update-job-in-catalog($job as element()) {
  let $jobName := $job/@name/data(.)
  let $previousJob := $pjs:catalog//job[@name eq $jobName]
  return
    if ( exists($previousJob) ) then
      update replace $previousJob with $job
    else
      update insert $job into $pjs:catalog/jobs
};

