page 80002 "Onb. Onboarding Subform"
{
    PageType = ListPart;
    Caption = 'Modules and Tasks';
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
                field("Assigned To"; Rec."Assigned To")
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Duration (Days)"; Rec."Duration (Days)")
                {
                    Editable = not IsGroup;
                    HideValue = IsGroup;
                }
                field(PlannedStart; PlannedStart)
                {
                    Caption = 'Planned Start Date';
                    ToolTip = 'Specifies when work on the task is planned to start. For a module or group it is the earliest start of the tasks below it.';
                    Editable = not IsGroup;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Planned Start Date", PlannedStart);
                    end;
                }
                field(PlannedEnd; PlannedEnd)
                {
                    Caption = 'Planned End Date';
                    ToolTip = 'Specifies when the task is planned to be finished. For a module or group it is the latest end of the tasks below it.';
                    Editable = not IsGroup;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Planned End Date", PlannedEnd);
                    end;
                }
                field(Status; Rec.Status)
                {
                    Editable = not IsGroup;
                    HideValue = IsGroup;
                    StyleExpr = StatusStyle;
                }
                field(GroupStatus; GroupStatusText)
                {
                    Caption = 'Group Status';
                    ToolTip = 'Specifies the status rolled up from the tasks below, with completed and applicable task counts.';
                    Editable = false;
                    HideValue = not IsGroup;
                }
                field(Notes; Rec.Notes)
                {
                    Editable = not IsGroup;
                    HideValue = IsGroup;
                }
                field("Completed By"; Rec."Completed By")
                {
                }
                field("Completed At"; Rec."Completed At")
                {
                }
                field(Instructions; Rec.Instructions)
                {
                    Visible = false;
                }
                field("Learn URL"; Rec."Learn URL")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkComplete)
            {
                Caption = 'Mark Complete';
                ToolTip = 'Complete the task, or every open task below it when it is a module or group.';
                Image = Approve;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.CompleteBranch(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenLearn)
            {
                Caption = 'Open Learn';
                ToolTip = 'Open the Microsoft Learn article for the task, or for the nearest line above it that has one.';
                Image = Help;

                trigger OnAction()
                var
                    OnbLineMgt: Codeunit "Onb. Line Mgt.";
                begin
                    OnbLineMgt.OpenLearn(Rec);
                end;
            }
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
            action(MyTasks)
            {
                Caption = 'My Tasks';
                ToolTip = 'Show only the tasks assigned to you, or show all tasks again.';
                Image = User;

                trigger OnAction()
                begin
                    MyTasksOnly := not MyTasksOnly;
                    if MyTasksOnly then
                        Rec.SetRange("Assigned To", CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned To")))
                    else
                        Rec.SetRange("Assigned To");
                    CurrPage.Update(false);
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
        StatusStyle := 'Standard';
        PlannedStart := 0D;
        PlannedEnd := 0D;
        GroupStatusText := '';
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
        Done: Integer;
        Total: Integer;
    begin
        IsGroup := false;
        if not IsNullGuid(Rec.SystemId) then
            IsGroup := OnbLineMgt.HasChildren(Rec);

        DescriptionStyle := 'Standard';
        if IsGroup then
            DescriptionStyle := 'Strong';

        StatusStyle := 'Standard';
        case Rec.Status of
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::"In Progress":
                StatusStyle := 'Ambiguous';
            Rec.Status::"Not Applicable":
                StatusStyle := 'Subordinate';
        end;

        PlannedStart := Rec."Planned Start Date";
        PlannedEnd := Rec."Planned End Date";
        if IsGroup then
            OnbLineMgt.GetPlannedDates(Rec, PlannedStart, PlannedEnd);

        GroupStatusText := '';
        if IsGroup then begin
            OnbLineMgt.GetBranchProgress(Rec, Done, Total);
            GroupStatusText := StrSubstNo(GroupStatusTxt, OnbLineMgt.GetRollupStatus(Rec), Done, Total);
        end;
    end;

    var
        MyTasksOnly: Boolean;
        IsGroup: Boolean;
        DescriptionStyle: Text;
        StatusStyle: Text;
        GroupStatusText: Text;
        PlannedStart: Date;
        PlannedEnd: Date;
        GroupStatusTxt: Label '%1 (%2/%3)', Comment = '%1 = rolled-up status, %2 = completed tasks, %3 = applicable tasks', Locked = true;
        DeleteGroupQst: Label 'Delete %1 and all of the lines below it?', Comment = '%1 = line description';
}
