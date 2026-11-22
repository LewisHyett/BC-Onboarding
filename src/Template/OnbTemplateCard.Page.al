page 80004 "Onb. Template Card"
{
    PageType = Card;
    Caption = 'Onboarding Template';
    ApplicationArea = All;
    SourceTable = "Onb. Template";

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
                field("Learn URL"; Rec."Learn URL")
                {
                }
                field("Source App Name"; Rec."Source App Name")
                {
                }
            }
            part(Lines; "Onb. Template Subform")
            {
                Caption = 'Lines';
                SubPageLink = "Document Type" = const(Template), "Document Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetToStandard)
            {
                Caption = 'Reset to Standard';
                ToolTip = 'Discard your changes to this template and get the standard version again from the extension that provides it.';
                Image = Restore;
                Enabled = IsStandard;

                trigger OnAction()
                var
                    OnbTemplateRegistry: Codeunit "Onb. Template Registry";
                begin
                    if not Confirm(ResetQst, false, Rec.Code) then
                        exit;
                    OnbTemplateRegistry.ResetTemplate(Rec.Code);
                    Rec.Get(Rec.Code);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ResetToStandard_Promoted; ResetToStandard)
            {
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNew := true;
        IsStandard := false;
    end;

    trigger OnAfterGetCurrRecord()
    var
        OnbTemplate: Record "Onb. Template";
    begin
        IsNew := not OnbTemplate.Get(Rec.Code);
        IsStandard := Rec.IsStandard();
    end;

    var
        IsNew: Boolean;
        IsStandard: Boolean;
        ResetQst: Label 'Reset template %1 to the standard version? Your changes to its lines are lost. Onboardings that already use it are not changed.', Comment = '%1 = template code';
}
