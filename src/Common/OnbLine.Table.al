table 80002 "Onb. Line"
{
    Caption = 'Onboarding Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Onb. Document Type")
        {
            ToolTip = 'Specifies whether the line belongs to a template or to an onboarding.';
            Caption = 'Document Type';
        }
        field(2; "Document Code"; Code[20])
        {
            ToolTip = 'Specifies the template or onboarding the line belongs to.';
            Caption = 'Document Code';
        }
        field(3; "Line No."; Integer)
        {
            ToolTip = 'Specifies the position of the line.';
            Caption = 'Line No.';
        }
        field(10; Description; Text[250])
        {
            ToolTip = 'Specifies what the task is.';
            Caption = 'Description';
        }
        field(11; Type; Enum "Onb. Task Type")
        {
            ToolTip = 'Specifies whether the task is something to read or something to test.';
            Caption = 'Type';
        }
        field(12; Indentation; Integer)
        {
            ToolTip = 'Specifies how deeply the line is nested. Use Indent and Outdent to change it.';
            Caption = 'Indentation';
            MinValue = 0;
            MaxValue = 9;
            Editable = false;
        }
        field(13; Instructions; Text[2048])
        {
            ToolTip = 'Specifies how to carry out the task.';
            Caption = 'Instructions';
        }
        field(14; "Learn URL"; Text[2048])
        {
            ToolTip = 'Specifies the Microsoft Learn article for the task. The link must start with https://.';
            Caption = 'Learn URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                OnbLineMgt: Codeunit "Onb. Line Mgt.";
            begin
                OnbLineMgt.CheckLearnUrl("Learn URL");
            end;
        }
        field(15; "Task Code"; Code[20])
        {
            ToolTip = 'Specifies the code an extension uses to identify its template line.';
            Caption = 'Task Code';
            Editable = false;
        }
        field(16; "Template Code"; Code[20])
        {
            ToolTip = 'Specifies the template the onboarding line was copied from.';
            Caption = 'Template Code';
            Editable = false;
        }
        field(17; "Template Line ID"; Guid)
        {
            ToolTip = 'Specifies the template line the onboarding line was copied from.';
            Caption = 'Template Line ID';
            Editable = false;
        }
        field(20; Status; Enum "Onb. Task Status")
        {
            ToolTip = 'Specifies the status of the task.';
            Caption = 'Status';

            trigger OnValidate()
            var
                OnbLineMgt: Codeunit "Onb. Line Mgt.";
            begin
                if Status = xRec.Status then
                    exit;
                if "Document Type" = "Document Type"::Template then
                    Error(TemplateStatusErr);
                if OnbLineMgt.HasChildren(Rec) then
                    Error(GroupStatusErr, Description);
                if Status = Status::Completed then begin
                    "Completed By" := CopyStr(UserId(), 1, MaxStrLen("Completed By"));
                    "Completed At" := CurrentDateTime();
                end else begin
                    Clear("Completed By");
                    Clear("Completed At");
                end;
            end;
        }
        field(21; "Completed By"; Code[50])
        {
            ToolTip = 'Specifies the user who completed the task.';
            Caption = 'Completed By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(22; "Completed At"; DateTime)
        {
            ToolTip = 'Specifies when the task was completed.';
            Caption = 'Completed At';
            Editable = false;
        }
        field(23; Notes; Text[2048])
        {
            ToolTip = 'Specifies your notes on the task.';
            Caption = 'Notes';
        }
        field(24; "Assigned To"; Code[50])
        {
            ToolTip = 'Specifies who is responsible for the task. Assigning a group also assigns the tasks below it that were unassigned or assigned to the same person.';
            Caption = 'Assigned To';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                OnbLineMgt: Codeunit "Onb. Line Mgt.";
            begin
                OnbLineMgt.AssignBranch(Rec, xRec."Assigned To");
            end;
        }
        field(25; "Planned Start Date"; Date)
        {
            ToolTip = 'Specifies when work on the task is planned to start.';
            Caption = 'Planned Start Date';

            trigger OnValidate()
            begin
                CheckPlannedDates();
            end;
        }
        field(26; "Planned End Date"; Date)
        {
            ToolTip = 'Specifies when the task is planned to be finished.';
            Caption = 'Planned End Date';

            trigger OnValidate()
            begin
                CheckPlannedDates();
            end;
        }
        field(27; "Duration (Days)"; Integer)
        {
            ToolTip = 'Specifies how many days the task is expected to take. Plan Dates on the onboarding uses it to fill in the planned dates.';
            Caption = 'Duration (Days)';
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Document Type", "Document Code", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        TestField("Document Code");
        OnbLineMgt.InheritAssignment(Rec);
    end;

    trigger OnDelete()
    var
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
    begin
        OnbLineMgt.DeleteChildren(Rec);
    end;

    var
        TemplateStatusErr: Label 'Status can''t be set on template lines.';
        GroupStatusErr: Label 'The status of %1 is calculated from the tasks below it and can''t be changed.', Comment = '%1 = line description';
        PlannedDatesErr: Label 'The planned end date %1 is before the planned start date %2.', Comment = '%1 = end date, %2 = start date';

    local procedure CheckPlannedDates()
    begin
        if ("Planned Start Date" <> 0D) and ("Planned End Date" <> 0D) and ("Planned End Date" < "Planned Start Date") then
            Error(PlannedDatesErr, "Planned End Date", "Planned Start Date");
    end;
}
