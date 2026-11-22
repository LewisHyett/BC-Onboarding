page 80003 "Onb. Template List"
{
    PageType = List;
    Caption = 'Onboarding Templates';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Onb. Template";
    SourceTableView = sorting(Sequence, Code);
    CardPageId = "Onb. Template Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Templates)
            {
                field(Code; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Source App Name"; Rec."Source App Name")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshTemplates)
            {
                Caption = 'Get Standard Templates';
                ToolTip = 'Add the standard templates from this app and other installed extensions that you don''t have yet. Templates you already have are not changed.';
                Image = Refresh;

                trigger OnAction()
                var
                    OnbTemplateRegistry: Codeunit "Onb. Template Registry";
                begin
                    OnbTemplateRegistry.RefreshTemplates();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RefreshTemplates_Promoted; RefreshTemplates)
            {
            }
        }
    }

    /// <summary>
    /// Applies the user's selection (in lookup mode) to OnbTemplate.
    /// </summary>
    procedure GetSelection(var OnbTemplate: Record "Onb. Template")
    begin
        CurrPage.SetSelectionFilter(OnbTemplate);
    end;
}
