codeunit 80003 "Onb. Install"
{
    Subtype = Install;
    Access = Internal;

    // Loads the standard templates. Onboardings start empty.
    trigger OnInstallAppPerCompany()
    var
        OnbTemplateRegistry: Codeunit "Onb. Template Registry";
    begin
        OnbTemplateRegistry.RefreshTemplates();
    end;
}
