page 80007 "Onb. Plan"
{
    // UserControlHost gives the chart all the available space. It allows one usercontrol and no actions,
    // so the onboarding is passed in with SetOnboardingCode, and you reopen the page to refresh it.
    PageType = UserControlHost;
    Caption = 'Onboarding Plan';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Gantt; "Onb. Gantt")
            {
                trigger ControlReady()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    CurrPage.Gantt.SetData(OnbLineMgt.GetGanttData(OnboardingCode));
                end;
            }
        }
    }

    procedure SetOnboardingCode(NewOnboardingCode: Code[20])
    begin
        OnboardingCode := NewOnboardingCode;
    end;

    var
        OnboardingCode: Code[20];
}
