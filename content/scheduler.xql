xquery version "3.0";

module namespace pcron "http://www.wwp.northeastern.edu/ns/persistent-scheduler";
import module namespace sched="http://exist-db.org/xquery/scheduler";
(: NAMESPACES :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : 
 :)
 
(: VARIABLES :)
  declare variable $catalog := doc('data/catalog.xml');

(: FUNCTIONS :)

declare function acron:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
                                                $job-name as xs:string, $job-parameters as element()?) {
  acron:schedule-xquery-cron-job($xq-filepath, $cron-expression, $job-name, $job-parameters, false())
};

declare function acron:schedule-xquery-cron-job($xq-filepath as xs:string, $cron-expression as xs:string, 
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
  let $previousJob := $catalog//job[@name eq $job-name]
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
    if ( $nowScheduled and exists($previousJob) ) then
      (
        update replace $previousJob with $jobListing,
        () (: LOG :)
      )
    else if ( $nowScheduled ) then
      (
        update insert $jobListing into $catalog/cron-jobs,
        () (: LOG :)
      )
    else
      () (: LOG :)
};

