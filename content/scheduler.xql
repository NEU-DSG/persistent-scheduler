xquery version "3.0";

module namespace pcron="http://www.wwp.northeastern.edu/ns/persistent-scheduler";
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
  
  @author Ashley M. Clark, Northeastern University Women Writers Project
  @version 0.0.1
  @since November 9, 2018
:)
 
(:  VARIABLES  :)
  declare %private variable $pcron:catalog := 
    let $absPath := repo:get-root()
    let $path := 'xmldb:exist://'||$absPath||'persistent-scheduler/data/catalog.xml'
    return doc($path);


(:  FUNCTIONS  :)

(:~
  Schedule a cron job implemented in XQuery. If a job already exists with the requested name, the task 
  will fail.
  
  @param xq-filepath is a path to the XQuery script which will be scheduled.
  @param cron-expression is the cron string representing when and for how long the job should run.
  @param job-name is the title given to the cron job. It must be unique to eXist's scheduler.
  @param job-parameters is an XML fragment containing parameter names and string values. E.g. `<parameters><param name="string" value="string"/></parameters>`
:)
declare function pcron:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
                                                $job-name as xs:string, $job-parameters as element()?) {
  pcron:schedule-xquery-cron-job($xq-filepath, $cron-expression, $job-name, $job-parameters, false())
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
:)
declare function pcron:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
                                                $job-name as xs:string, $job-parameters as element()?, $force as xs:boolean) {
  let $previouslyScheduled :=
    exists(sched:get-scheduled-jobs()//sched:job[@name eq $job-name])
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
        pcron:update-job-in-catalog($jobListing),
        () (: LOG :)
      )
    else
      () (: LOG :)
};


(:  FUNCTIONS, PRIVATE  :)

(: Create or update a scheduled job in the catalog. This should only be used when a job has been 
  successfully scheduled. :)
declare %private function pcron:update-job-in-catalog($job as element()) {
  let $jobName := $job/@name/data(.)
  let $previousJob := $pcron:catalog//job[@name eq $jobName]
  return
    if ( exists($previousJob) ) then
      update replace $previousJob with $job
    else
      update insert $job into $pcron:catalog/cron-jobs
};

