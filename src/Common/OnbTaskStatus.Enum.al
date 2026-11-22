enum 80001 "Onb. Task Status"
{
    Extensible = false;
    Caption = 'Onboarding Task Status';

    value(0; "Not Started")
    {
        Caption = 'Not Started';
    }
    value(1; "In Progress")
    {
        Caption = 'In Progress';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
    value(3; "Not Applicable")
    {
        Caption = 'Not Applicable';
    }
}
