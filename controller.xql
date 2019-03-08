xquery version "3.0";

(:~
  
 :)
 
(:  VARIABLES  :)
  declare variable $exist:path external;
  declare variable $exist:resource external;
  declare variable $exist:controller external;
  declare variable $exist:prefix external;
  declare variable $exist:root external;


(:  MAIN QUERY  :)

<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <forward url="{$exist:controller}/content/index.xq"/>
</dispatch>
