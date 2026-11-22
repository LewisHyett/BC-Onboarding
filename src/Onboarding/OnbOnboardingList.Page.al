page 80000 "Onb. Onboarding List"
{
    PageType = List;
    Caption = 'Onboardings';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Onb. Onboarding";
    CardPageId = "Onb. Onboarding Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Onboardings)
            {
                field(Code; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field(Tasks; Tasks)
                {
                    Caption = 'Tasks';
                    ToolTip = 'Specifies the number of tasks, not counting modules and other groups.';
                }
                field(Completed; Completed)
                {
                    Caption = 'Completed';
                    ToolTip = 'Specifies the number of completed tasks.';
                }
                field(ProgressPct; ProgressPct)
                {
                    Caption = 'Progress %';
                    ToolTip = 'Specifies the share of applicable tasks that are completed.';
                    StyleExpr = ProgressStyle;
                    DecimalPlaces = 0 : 1;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Templates)
            {
                Caption = 'Onboarding Templates';
                ToolTip = 'View and change the templates you can select as modules on an onboarding.';
                Image = Template;
                RunObject = page "Onb. Template List";
            }
        }
        area(Promoted)
        {
            actionref(Templates_Promoted; Templates)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
        NotApplicable: Integer;
    begin
        OnbLineMgt.GetOnboardingProgress(Rec.Code, Tasks, Completed, NotApplicable);
        ProgressPct := OnbLineMgt.GetProgressPct(Tasks, Completed, NotApplicable);
        ProgressStyle := 'Standard';
        if (ProgressPct = 100) and (Tasks > 0) then
            ProgressStyle := 'Favorable';
    end;

    var
        Tasks: Integer;
        Completed: Integer;
        ProgressPct: Decimal;
        ProgressStyle: Text;
}
