page 80005 "Onb. Template Subform"
{
    PageType = ListPart;
    Caption = 'Lines';
    ApplicationArea = All;
    SourceTable = "Onb. Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                // Fixed indentation like Job Task lines: a collapsible ShowAsTree list doesn't allow inserting new lines.
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;

                field(Description; Rec.Description)
                {
                    StyleExpr = DescriptionStyle;
                }
                field(Type; Rec.Type)
                {
                    HideValue = IsGroup;
                }
                field("Duration (Days)"; Rec."Duration (Days)")
                {
                    HideValue = IsGroup;
                }
                field(Instructions; Rec.Instructions)
                {
                }
                field("Learn URL"; Rec."Learn URL")
                {
                }
                field("Task Code"; Rec."Task Code")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Indent)
            {
                Caption = 'Indent';
                ToolTip = 'Make the line a sub-task of the line above it. The lines below it move with it.';
                Image = Indent;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.Indent(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Outdent)
            {
                Caption = 'Outdent';
                ToolTip = 'Move the line one level up. The lines below it move with it.';
                Image = DecreaseIndent;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.Outdent(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(MoveUp)
            {
                Caption = 'Move Up';
                ToolTip = 'Move the line above the previous line at the same level. The lines below it move with it.';
                Image = MoveUp;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.MoveBlock(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(MoveDown)
            {
                Caption = 'Move Down';
                ToolTip = 'Move the line below the next line at the same level. The lines below it move with it.';
                Image = MoveDown;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.MoveBlock(Rec, false);
                    CurrPage.Update(false);
                end;
            }
            action(OpenLearn)
            {
                Caption = 'Open Learn';
                ToolTip = 'Open the Microsoft Learn article for the line, or for the nearest line above it that has one.';
                Image = Help;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.OpenLearn(Rec);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        // A new line takes the level of the line it's inserted next to; directly below a group, it becomes its first sub-task.
        Rec.Indentation := xRec.Indentation;
        if BelowxRec and not IsNullGuid(xRec.SystemId) then
            if OnbLineMgt.HasChildren(xRec) then
                Rec.Indentation := xRec.Indentation + 1;
        IsGroup := false;
        DescriptionStyle := 'Standard';
    end;

    trigger OnAfterGetRecord()
    begin
        SetRowState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetRowState();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        if OnbLineMgt.HasChildren(Rec) then
            if not Confirm(DeleteGroupQst, false, Rec.Description) then
                exit(false);
    end;

    local procedure SetRowState()
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        IsGroup := false;
        if not IsNullGuid(Rec.SystemId) then
            IsGroup := OnbLineMgt.HasChildren(Rec);
        DescriptionStyle := 'Standard';
        if IsGroup then
            DescriptionStyle := 'Strong';
    end;

    var
        IsGroup: Boolean;
        DescriptionStyle: Text;
        DeleteGroupQst: Label 'Delete %1 and all of the lines below it?', Comment = '%1 = line description';
}
