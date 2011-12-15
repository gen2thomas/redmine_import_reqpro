class IssueAdd
  # Patches Redmine's Issue with additional types
      
  ISSUE_ISBUG = "Bug"
  ISSUE_ISSTORY = "Story"
  ISSUE_ISNEED = "Need"
  ISSUE_ISFUNC = "Function"
  ISSUE_ISFEAT = "Feature"
  ISSUE_ISSPEC = "Specification"
  ISSUE_ISTESTC = "Testcase"

  KUP_TRACES = { 
    ISSUE_ISBUG   => { :rel_to => ISSUE_ISNEED},
    ISSUE_ISSTORY => { :rel_to => ISSUE_ISNEED},
    ISSUE_ISNEED  => { :rel_to => [ISSUE_ISBUG, ISSUE_ISSTORY, ISSUE_ISFUNC]},
    ISSUE_ISFUNC  => { :rel_to => [ISSUE_ISNEED, ISSUE_ISFEAT, ISSUE_ISSPEC, ISSUE_ISTESTC]},
    ISSUE_ISFEAT  => { :rel_to => ISSUE_ISFUNC},
    ISSUE_ISSPEC  => { :rel_to => ISSUE_ISFUNC},
    ISSUE_ISTESTC => { :rel_to => ISSUE_ISFUNC}
    }
end