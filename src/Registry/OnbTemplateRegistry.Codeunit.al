codeunit 80000 "Onb. Template Registry"
{
    // Extensions provide standard templates by subscribing to OnRegisterTemplates.
    // A template is only created when its code doesn't exist yet. After that it belongs to the customer:
    // they can change it freely, and Refresh never overwrites it. Reset to Standard recreates it.

    var
        CreatedTemplates: List of [Code[20]];
        StandardSourceLbl: Label 'Business Central';
        TemplateMissingErr: Label 'Template %1 must be registered with AddTemplateModule before its tasks.', Comment = '%1 = template code';
        ParentMissingErr: Label 'Parent task %1 must be registered in template %2 before its sub-tasks.', Comment = '%1 = task code, %2 = template code';
        NotStandardErr: Label 'Template %1 was not provided by an extension, so there is no standard version to reset to.', Comment = '%1 = template code';
        NotRecreatedErr: Label 'Template %1 could not be reset because no installed extension provides it any more.', Comment = '%1 = template code';

    /// <summary>
    /// Creates the standard templates that don't exist yet. Existing templates are left as they are.
    /// </summary>
    procedure RefreshTemplates()
    var
        Registry: Codeunit "Onb. Template Registry";
    begin
        Clear(CreatedTemplates);
        // Codeunit variables are references: subscribers write to this same instance.
        Registry := this;
        OnRegisterTemplates(Registry);
    end;

    /// <summary>
    /// Deletes the template and creates it again from the extension that provides it, discarding the customer's changes.
    /// </summary>
    procedure ResetTemplate(TemplateCode: Code[20])
    var
        OnbTemplate: Record "Onb. Template";
    begin
        OnbTemplate.Get(TemplateCode);
        if not OnbTemplate.IsStandard() then
            Error(NotStandardErr, TemplateCode);
        OnbTemplate.Delete(true);
        RefreshTemplates();
        if not OnbTemplate.Get(TemplateCode) then
            Error(NotRecreatedErr, TemplateCode);
    end;

    /// <summary>
    /// Creates a template owned by the calling extension. Returns false when the code already exists,
    /// in which case the AddTemplateTask calls for it are ignored too.
    /// </summary>
    procedure AddTemplateModule(ModuleCode: Code[20]; Description: Text[100]; Sequence: Integer; LearnUrl: Text[2048]): Boolean
    var
        OnbTemplate: Record "Onb. Template";
        CallerModuleInfo: ModuleInfo;
        CurrentModuleInfo: ModuleInfo;
    begin
        // Must be called directly here: it returns the app that called this procedure.
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        if OnbTemplate.Get(ModuleCode) then
            exit(false);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        OnbTemplate.Init();
        OnbTemplate.Code := ModuleCode;
        OnbTemplate.Description := Description;
        OnbTemplate.Sequence := Sequence;
        OnbTemplate.Validate("Learn URL", LearnUrl);
        OnbTemplate."Source App ID" := CallerModuleInfo.Id;
        if CallerModuleInfo.Id = CurrentModuleInfo.Id then
            OnbTemplate."Source App Name" := StandardSourceLbl
        else
            OnbTemplate."Source App Name" := CopyStr(CallerModuleInfo.Name, 1, MaxStrLen(OnbTemplate."Source App Name"));
        OnbTemplate.Insert(true);
        CreatedTemplates.Add(ModuleCode);
        exit(true);
    end;

    /// <summary>
    /// Adds a line to a template the calling extension created in this refresh. Lines are added in the order
    /// of the calls, so register them top to bottom with each parent before its sub-tasks. A blank
    /// ParentTaskCode puts the task at the top level of the template.
    /// </summary>
    procedure AddTemplateTask(ModuleCode: Code[20]; ParentTaskCode: Code[20]; TaskCode: Code[20]; Description: Text[250]; TaskType: Enum "Onb. Task Type"; Instructions: Text[2048]; LearnUrl: Text[2048]): Boolean
    var
        OnbTemplate: Record "Onb. Template";
        OnbLine: Record "Onb. Line";
        ParentLine: Record "Onb. Line";
        OnbLineMgt: Codeunit "Onb. Line Mgt.";
        CallerModuleInfo: ModuleInfo;
    begin
        // Must be called directly here: it returns the app that called this procedure.
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        if not OnbTemplate.Get(ModuleCode) then
            Error(TemplateMissingErr, ModuleCode);
        if not CreatedTemplates.Contains(ModuleCode) then
            exit(false);
        if OnbTemplate."Source App ID" <> CallerModuleInfo.Id then
            exit(false);

        OnbLine.Init();
        OnbLine."Document Type" := OnbLine."Document Type"::Template;
        OnbLine."Document Code" := ModuleCode;
        OnbLine."Line No." := OnbLineMgt.GetLineNoAfter(OnbLine."Document Type", ModuleCode, OnbLineMgt.GetLastLineNo(OnbLine."Document Type", ModuleCode));
        if ParentTaskCode <> '' then begin
            ParentLine.SetRange("Document Type", ParentLine."Document Type"::Template);
            ParentLine.SetRange("Document Code", ModuleCode);
            ParentLine.SetRange("Task Code", ParentTaskCode);
            if not ParentLine.FindFirst() then
                Error(ParentMissingErr, ParentTaskCode, ModuleCode);
            OnbLine.Indentation := ParentLine.Indentation + 1;
        end;
        OnbLine."Task Code" := TaskCode;
        OnbLine.Description := Description;
        OnbLine.Type := TaskType;
        OnbLine.Instructions := Instructions;
        OnbLine.Validate("Learn URL", LearnUrl);
        OnbLine.Insert(true);
        exit(true);
    end;

    /// <summary>
    /// Subscribers call AddTemplateModule and then AddTemplateTask on Registry. No Commit in subscribers.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnRegisterTemplates(var Registry: Codeunit "Onb. Template Registry")
    begin
    end;
}
