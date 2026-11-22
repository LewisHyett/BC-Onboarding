table 80000 "Onb. Template"
{
    Caption = 'Onboarding Template';
    DataClassification = CustomerContent;
    LookupPageId = "Onb. Template List";
    DrillDownPageId = "Onb. Template List";

    fields
    {
        field(1; Code; Code[20])
        {
            ToolTip = 'Specifies the code of the template. It becomes a module when you select it on an onboarding.';
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            ToolTip = 'Specifies what the template covers.';
            Caption = 'Description';
        }
        field(3; "Learn URL"; Text[2048])
        {
            ToolTip = 'Specifies the Microsoft Learn article for the template. The link must start with https://.';
            Caption = 'Learn URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                OnbLineMgt: Codeunit "Onb. Line Mgt.";
            begin
                OnbLineMgt.CheckLearnUrl("Learn URL");
            end;
        }
        field(4; Sequence; Integer)
        {
            ToolTip = 'Specifies the order of the template in the list.';
            Caption = 'Sequence';
            MinValue = 0;
        }
        field(5; "Source App ID"; Guid)
        {
            ToolTip = 'Specifies the ID of the extension that provided the template.';
            Caption = 'Source App ID';
            Editable = false;
        }
        field(6; "Source App Name"; Text[250])
        {
            ToolTip = 'Specifies the extension that provided the template. Blank for templates you created yourself.';
            Caption = 'Source';
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Key2; Sequence, Code)
        {
        }
    }

    trigger OnDelete()
    var
        OnbLine: Record "Onb. Line";
    begin
        OnbLine.SetRange("Document Type", OnbLine."Document Type"::Template);
        OnbLine.SetRange("Document Code", Code);
        OnbLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr, xRec.Code);
    end;

    var
        RenameNotAllowedErr: Label 'You can''t rename template %1.', Comment = '%1 = template code';

    procedure IsStandard(): Boolean
    begin
        exit(not IsNullGuid("Source App ID"));
    end;
}
