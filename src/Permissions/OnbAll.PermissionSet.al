permissionset 80000 "ONB ALL"
{
    Assignable = true;
    Caption = 'Onboarding - All';

    Permissions =
        tabledata "Onb. Template" = RIMD,
        tabledata "Onb. Onboarding" = RIMD,
        tabledata "Onb. Line" = RIMD,
        table "Onb. Template" = X,
        table "Onb. Onboarding" = X,
        table "Onb. Line" = X,
        codeunit "Onb. Template Registry" = X,
        codeunit "Onb. Std. Templates" = X,
        codeunit "Onb. Line Mgt." = X,
        codeunit "Onb. Install" = X,
        page "Onb. Onboarding List" = X,
        page "Onb. Onboarding Card" = X,
        page "Onb. Onboarding Subform" = X,
        page "Onb. Template List" = X,
        page "Onb. Template Card" = X,
        page "Onb. Template Subform" = X,
        page "Onb. Gantt Part" = X,
        page "Onb. Plan" = X;
}
