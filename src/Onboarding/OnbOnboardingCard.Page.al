page 80001 "Onb. Onboarding Card"
{
    PageType = Card;
    Caption = 'Onboarding';
    ApplicationArea = All;
    SourceTable = "Onb. Onboarding";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    Editable = IsNew;
                }
                field(Description; Rec.Description)
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("Start Date"; Rec."Start Date")
                {
                }
                field(ProgressPct; ProgressPct)
                {
                    Caption = 'Progress %';
                    ToolTip = 'Specifies the share of applicable tasks that are completed.';
                    Editable = false;
                    DecimalPlaces = 0 : 1;
                }
            }
            part(Lines; "Onb. Onboarding Subform")
            {
                Caption = 'Modules and Tasks';
                SubPageLink = "Document Type" = const(Onboarding), "Document Code" = field(Code);
                UpdatePropagation = Both;
            }
            part(Plan; "Onb. Gantt Part")
            {
                Caption = 'Plan';
                SubPageLink = Code = field(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectModules)
            {
                Caption = 'Select Modules';
                ToolTip = 'Choose templates to add to this onboarding as modules. Modules it already has only get the tasks they are missing.';
                Image = ApplyTemplate;

                trigger OnAction()
                var
                    SelectedTemplate: Record "Onb. Template";
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                    OnbTemplateList: Page "Onb. Template List";
                begin
                    Rec.TestField(Code);
                    OnbTemplateList.LookupMode(true);
                    if OnbTemplateList.RunModal() <> Action::LookupOK then
                        exit;
                    OnbTemplateList.GetSelection(SelectedTemplate);
                    OnbLineMgt.CopyTemplates(SelectedTemplate, Rec.Code);
                    CurrPage.Update(false);
                end;
            }
            action(PlanDates)
            {
                Caption = 'Plan Dates';
                ToolTip = 'Fill in the planned dates of all tasks from the Start Date and each task''s duration. Modules run side by side; tasks inside a module run one after another.';
                Image = CalculatePlan;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    Rec.TestField("Start Date");
                    if not Confirm(PlanDatesQst, false) then
                        exit;
                    OnbLineMgt.PlanDates(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PlanFullScreen)
            {
                Caption = 'Plan (Full Screen)';
                ToolTip = 'Open the Gantt chart of this onboarding on a page of its own that uses all the available space.';
                Image = Timeline;

                trigger OnAction()
                var
                    OnbPlan: Page "Onb. Plan";
                begin
                    Rec.TestField(Code);
                    OnbPlan.SetOnboardingCode(Rec.Code);
                    OnbPlan.Run();
                end;
            }
        }
        area(Promoted)
        {
            actionref(SelectModules_Promoted; SelectModules)
            {
            }
            actionref(PlanDates_Promoted; PlanDates)
            {
            }
            actionref(PlanFullScreen_Promoted; PlanFullScreen)
            {
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNew := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        OnbOnboarding: Record "Onb. Onboarding";
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
        Tasks: Integer;
        Completed: Integer;
        NotApplicable: Integer;
    begin
        IsNew := not OnbOnboarding.Get(Rec.Code);
        OnbLineMgt.GetOnboardingProgress(Rec.Code, Tasks, Completed, NotApplicable);
        ProgressPct := OnbLineMgt.GetProgressPct(Tasks, Completed, NotApplicable);
    end;

    var
        IsNew: Boolean;
        ProgressPct: Decimal;
        PlanDatesQst: Label 'Plan Dates replaces the planned dates of all tasks on this onboarding. Continue?';
}
