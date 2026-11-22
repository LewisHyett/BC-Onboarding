table 80001 "Onb. Onboarding"
{
    Caption = 'Onboarding';
    DataClassification = CustomerContent;
    LookupPageId = "Onb. Onboarding List";
    DrillDownPageId = "Onb. Onboarding List";

    fields
    {
        field(1; Code; Code[20])
        {
            ToolTip = 'Specifies the code of the onboarding.';
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            ToolTip = 'Specifies what the onboarding is for.';
            Caption = 'Description';
        }
        field(3; "User ID"; Code[50])
        {
            ToolTip = 'Specifies the person the onboarding is for. Leave blank for an onboarding shared by the team.';
            Caption = 'Onboarding For';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(4; "Start Date"; Date)
        {
            ToolTip = 'Specifies when the onboarding starts. Plan Dates schedules the tasks from this date.';
            Caption = 'Start Date';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        OnbLine: Record "Onb. Line";
    begin
        OnbLine.SetRange("Document Type", OnbLine."Document Type"::Onboarding);
        OnbLine.SetRange("Document Code", Code);
        OnbLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec.Code);
    end;

    var
        RenameNotAllowedErr: Label 'You can''t rename onboarding %1.', Comment = '%1 = onboarding code';
}
