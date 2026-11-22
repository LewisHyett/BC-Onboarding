page 80006 "Onb. Gantt Part"
{
    PageType = CardPart;
    Caption = 'Plan';
    ApplicationArea = All;
    SourceTable = "Onb. Onboarding";
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(Gantt; "Onb. Gantt")
            {
                trigger ControlReady()
                begin
                    IsReady := true;
                    SendData();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SendData();
    end;

    local procedure SendData()
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        if IsReady then
            CurrPage.Gantt.SetData(OnbLineMgt.GetGanttData(Rec.Code));
    end;

    var
        IsReady: Boolean;
}
