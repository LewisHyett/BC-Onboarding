codeunit 80002 "Onb. Line Mgt."
{
    // Lines form a tree through Indentation, like Job Tasks: a line's children are the lines
    // directly after it with a higher Indentation. A line with children is a group.

    var
        TemplateStatusErr: Label 'Status can''t be set on template lines.';
        NoLearnLinkErr: Label 'No Microsoft Learn link is set for %1.', Comment = '%1 = line description';
        InvalidUrlErr: Label 'The link %1 must start with https://.', Comment = '%1 = the URL entered';
        CannotIndentErr: Label 'The line can''t be indented further. A line can be at most one level deeper than the line above it, and at most 10 levels deep.';
        CannotOutdentErr: Label 'The line is already at the top level.';
        NoRoomErr: Label 'There is no room to insert a line after line %1. Move some lines to make room.', Comment = '%1 = line number';
        CopyResultMsg: Label '%1 modules selected. %2 tasks added, %3 already present.', Comment = '%1 = number of modules, %2 = tasks added, %3 = tasks already present';
        PlanDatesMsg: Label '%1 tasks planned.', Comment = '%1 = number of tasks';
        HttpsPrefixTxt: Label 'https://', Locked = true;

    procedure HasChildren(OnbLine: Record "Onb. Line"): Boolean
    var
        NextLine: Record "Onb. Line";
    begin
        if not FindNextLine(OnbLine, NextLine) then
            exit(false);
        exit(NextLine.Indentation > OnbLine.Indentation);
    end;

    /// <summary>
    /// Line No. of the last line in the block that starts at OnbLine (the line and all lines below it).
    /// </summary>
    procedure GetBlockEnd(OnbLine: Record "Onb. Line"): Integer
    var
        NextLine: Record "Onb. Line";
        BlockEnd: Integer;
    begin
        BlockEnd := OnbLine."Line No.";
        FilterDocument(NextLine, OnbLine);
        NextLine.SetFilter("Line No.", '>%1', OnbLine."Line No.");
        if NextLine.FindSet() then
            repeat
                if NextLine.Indentation <= OnbLine.Indentation then
                    exit(BlockEnd);
                BlockEnd := NextLine."Line No.";
            until NextLine.Next() = 0;
        exit(BlockEnd);
    end;

    procedure GetParent(OnbLine: Record "Onb. Line"; var ParentLine: Record "Onb. Line"): Boolean
    begin
        if OnbLine.Indentation = 0 then
            exit(false);
        FilterDocument(ParentLine, OnbLine);
        ParentLine.SetFilter("Line No.", '<%1', OnbLine."Line No.");
        ParentLine.SetFilter(Indentation, '<%1', OnbLine.Indentation);
        exit(ParentLine.FindLast());
    end;

    /// <summary>
    /// A task's own status, or for a group the status rolled up from the tasks below it.
    /// </summary>
    procedure GetRollupStatus(OnbLine: Record "Onb. Line"): Enum "Onb. Task Status"
    var
        Leaves: Integer;
        Completed: Integer;
        NotApplicable: Integer;
        NotStarted: Integer;
    begin
        if not HasChildren(OnbLine) then
            exit(OnbLine.Status);
        CountLeaves(OnbLine, OnbLine."Line No." + 1, GetBlockEnd(OnbLine), Leaves, Completed, NotApplicable, NotStarted);
        if Completed + NotApplicable = Leaves then
            exit("Onb. Task Status"::Completed);
        if NotStarted < Leaves then
            exit("Onb. Task Status"::"In Progress");
        exit("Onb. Task Status"::"Not Started");
    end;

    /// <summary>
    /// For a group: Done = completed tasks below it; Total = tasks below it that are not Not Applicable.
    /// </summary>
    procedure GetBranchProgress(OnbLine: Record "Onb. Line"; var Done: Integer; var Total: Integer)
    var
        Leaves: Integer;
        NotApplicable: Integer;
        NotStarted: Integer;
    begin
        Done := 0;
        CountLeaves(OnbLine, OnbLine."Line No." + 1, GetBlockEnd(OnbLine), Leaves, Done, NotApplicable, NotStarted);
        Total := Leaves - NotApplicable;
    end;

    /// <summary>
    /// Task counts for a whole onboarding. Groups are not counted, only the tasks in them.
    /// </summary>
    procedure GetOnboardingProgress(OnboardingCode: Code[20]; var Tasks: Integer; var Completed: Integer; var NotApplicable: Integer)
    var
        OnbLine: Record "Onb. Line";
        NotStarted: Integer;
    begin
        Tasks := 0;
        Completed := 0;
        NotApplicable := 0;
        OnbLine."Document Type" := OnbLine."Document Type"::Onboarding;
        OnbLine."Document Code" := OnboardingCode;
        CountLeaves(OnbLine, 0, 2147483647, Tasks, Completed, NotApplicable, NotStarted);
    end;

    procedure GetProgressPct(Tasks: Integer; Completed: Integer; NotApplicable: Integer): Decimal
    begin
        if Tasks - NotApplicable <= 0 then
            exit(100);
        exit(Round(Completed / (Tasks - NotApplicable) * 100, 1));
    end;

    /// <summary>
    /// Completes the task, or every open task below it when it is a group.
    /// </summary>
    procedure CompleteBranch(OnbLine: Record "Onb. Line")
    var
        BranchLine: Record "Onb. Line";
        NextLine: Record "Onb. Line";
        IsLeaf: Boolean;
    begin
        if OnbLine."Document Type" = OnbLine."Document Type"::Template then
            Error(TemplateStatusErr);
        FilterDocument(BranchLine, OnbLine);
        BranchLine.SetRange("Line No.", OnbLine."Line No.", GetBlockEnd(OnbLine));
        if BranchLine.FindSet(true) then
            repeat
                IsLeaf := true;
                if FindNextLine(BranchLine, NextLine) then
                    IsLeaf := NextLine.Indentation <= BranchLine.Indentation;
                if IsLeaf and not (BranchLine.Status in [BranchLine.Status::Completed, BranchLine.Status::"Not Applicable"]) then begin
                    BranchLine.Validate(Status, BranchLine.Status::Completed);
                    BranchLine.Modify(true);
                end;
            until BranchLine.Next() = 0;
    end;

    /// <summary>
    /// Moves the line and the lines below it one level deeper.
    /// </summary>
    procedure Indent(var OnbLine: Record "Onb. Line")
    var
        PreviousLine: Record "Onb. Line";
    begin
        FilterDocument(PreviousLine, OnbLine);
        PreviousLine.SetFilter("Line No.", '<%1', OnbLine."Line No.");
        if not PreviousLine.FindLast() then
            Error(CannotIndentErr);
        if OnbLine.Indentation > PreviousLine.Indentation then
            Error(CannotIndentErr);
        ShiftBlock(OnbLine, 1);
    end;

    /// <summary>
    /// Moves the line and the lines below it one level up.
    /// </summary>
    procedure Outdent(var OnbLine: Record "Onb. Line")
    begin
        if OnbLine.Indentation = 0 then
            Error(CannotOutdentErr);
        ShiftBlock(OnbLine, -1);
    end;

    /// <summary>
    /// Swaps the line (with the lines below it) with the previous or next line at the same level (with the lines below that).
    /// Lines keep their SystemId, so copies made from template lines still recognise them.
    /// </summary>
    procedure MoveBlock(var OnbLine: Record "Onb. Line"; MoveUp: Boolean)
    var
        OtherLine: Record "Onb. Line";
        RangeLine: Record "Onb. Line";
        TempOrderedLine: Record "Onb. Line" temporary;
        Slots: List of [Integer];
        Ids: List of [Guid];
        MovedId: Guid;
        FirstStart: Integer;
        FirstEnd: Integer;
        SecondStart: Integer;
        SecondEnd: Integer;
        Index: Integer;
    begin
        FilterDocument(OtherLine, OnbLine);
        if MoveUp then begin
            OtherLine.SetFilter("Line No.", '<%1', OnbLine."Line No.");
            OtherLine.SetFilter(Indentation, '<=%1', OnbLine.Indentation);
            if not OtherLine.FindLast() then
                exit;
            if OtherLine.Indentation < OnbLine.Indentation then
                exit; // first child of its parent
            FirstStart := OtherLine."Line No.";
            FirstEnd := OnbLine."Line No." - 1;
            SecondStart := OnbLine."Line No.";
            SecondEnd := GetBlockEnd(OnbLine);
        end else begin
            FirstStart := OnbLine."Line No.";
            FirstEnd := GetBlockEnd(OnbLine);
            OtherLine.SetFilter("Line No.", '>%1', FirstEnd);
            if not OtherLine.FindFirst() then
                exit;
            if OtherLine.Indentation < OnbLine.Indentation then
                exit; // last child of its parent
            SecondStart := OtherLine."Line No.";
            SecondEnd := GetBlockEnd(OtherLine);
        end;
        MovedId := OnbLine.SystemId;

        // New order: second block, then first block. The line numbers (slots) stay the same.
        FilterDocument(RangeLine, OnbLine);
        RangeLine.SetRange("Line No.", FirstStart, SecondEnd);
        if RangeLine.FindSet() then
            repeat
                Slots.Add(RangeLine."Line No.");
            until RangeLine.Next() = 0;
        AddToOrder(RangeLine, SecondStart, SecondEnd, TempOrderedLine, Ids);
        AddToOrder(RangeLine, FirstStart, FirstEnd, TempOrderedLine, Ids);

        RangeLine.SetRange("Line No.", FirstStart, SecondEnd);
        RangeLine.DeleteAll();
        for Index := 1 to Slots.Count() do begin
            TempOrderedLine.Get(OnbLine."Document Type", OnbLine."Document Code", Index);
            RangeLine := TempOrderedLine;
            RangeLine."Line No." := Slots.Get(Index);
            RangeLine.SystemId := Ids.Get(Index);
            RangeLine.Insert(false, true);
        end;
        OnbLine.GetBySystemId(MovedId);
    end;

    /// <summary>
    /// Carries an assignment down the branch: tasks below that were unassigned or assigned to the previous person follow.
    /// </summary>
    procedure AssignBranch(OnbLine: Record "Onb. Line"; PreviousAssignee: Code[50])
    var
        BranchLine: Record "Onb. Line";
    begin
        FilterDocument(BranchLine, OnbLine);
        BranchLine.SetRange("Line No.", OnbLine."Line No." + 1, GetBlockEnd(OnbLine));
        BranchLine.SetFilter("Assigned To", '%1|%2', '', PreviousAssignee);
        BranchLine.ModifyAll("Assigned To", OnbLine."Assigned To");
    end;

    procedure InheritAssignment(var OnbLine: Record "Onb. Line")
    var
        ParentLine: Record "Onb. Line";
    begin
        if OnbLine."Assigned To" <> '' then
            exit;
        if GetParent(OnbLine, ParentLine) then
            OnbLine."Assigned To" := ParentLine."Assigned To";
    end;

    procedure DeleteChildren(OnbLine: Record "Onb. Line")
    var
        ChildLine: Record "Onb. Line";
    begin
        FilterDocument(ChildLine, OnbLine);
        ChildLine.SetRange("Line No.", OnbLine."Line No." + 1, GetBlockEnd(OnbLine));
        ChildLine.DeleteAll();
    end;

    /// <summary>
    /// Opens the line's Learn link, falling back to its parents and then to the template.
    /// </summary>
    procedure OpenLearn(OnbLine: Record "Onb. Line")
    var
        CurrentLine: Record "Onb. Line";
        OnbTemplate: Record "Onb. Template";
    begin
        CurrentLine := OnbLine;
        repeat
            if CurrentLine."Learn URL" <> '' then begin
                Hyperlink(CurrentLine."Learn URL");
                exit;
            end;
        until not GetParent(CurrentLine, CurrentLine);
        if OnbLine."Document Type" = OnbLine."Document Type"::Template then
            if OnbTemplate.Get(OnbLine."Document Code") then
                if OnbTemplate."Learn URL" <> '' then begin
                    Hyperlink(OnbTemplate."Learn URL");
                    exit;
                end;
        Error(NoLearnLinkErr, OnbLine.Description);
    end;

    /// <summary>
    /// A task's own planned dates, or for a group the earliest start and latest end of the tasks below it.
    /// </summary>
    procedure GetPlannedDates(OnbLine: Record "Onb. Line"; var StartDate: Date; var EndDate: Date)
    var
        BranchLine: Record "Onb. Line";
    begin
        StartDate := OnbLine."Planned Start Date";
        EndDate := OnbLine."Planned End Date";
        if not HasChildren(OnbLine) then
            exit;
        StartDate := 0D;
        EndDate := 0D;
        FilterDocument(BranchLine, OnbLine);
        BranchLine.SetRange("Line No.", OnbLine."Line No." + 1, GetBlockEnd(OnbLine));
        if BranchLine.FindSet() then
            repeat
                // Only tasks count; groups inside the branch have no dates of their own.
                if not HasChildren(BranchLine) then begin
                    if (BranchLine."Planned Start Date" <> 0D) and ((StartDate = 0D) or (BranchLine."Planned Start Date" < StartDate)) then
                        StartDate := BranchLine."Planned Start Date";
                    if BranchLine."Planned End Date" > EndDate then
                        EndDate := BranchLine."Planned End Date";
                end;
            until BranchLine.Next() = 0;
    end;

    /// <summary>
    /// Fills in planned dates for every task from the onboarding's Start Date. Modules run side by side, each
    /// starting on the Start Date; inside a module the tasks run one after another in line order.
    /// A task takes Duration (Days) calendar days, at least one.
    /// </summary>
    procedure PlanDates(OnbOnboarding: Record "Onb. Onboarding")
    var
        OnbLine: Record "Onb. Line";
        NextLine: Record "Onb. Line";
        NextStart: Date;
        Planned: Integer;
        Days: Integer;
    begin
        OnbOnboarding.TestField("Start Date");
        OnbLine.SetRange("Document Type", OnbLine."Document Type"::Onboarding);
        OnbLine.SetRange("Document Code", OnbOnboarding.Code);
        if OnbLine.FindSet(true) then
            repeat
                if OnbLine.Indentation = 0 then
                    NextStart := OnbOnboarding."Start Date";
                // shortcut: calendar days, no base calendar or weekends; add a calendar if customers need working days.
                if not (FindNextLine(OnbLine, NextLine) and (NextLine.Indentation > OnbLine.Indentation)) then begin
                    Days := OnbLine."Duration (Days)";
                    if Days < 1 then
                        Days := 1;
                    OnbLine."Planned Start Date" := NextStart;
                    OnbLine."Planned End Date" := NextStart + Days - 1;
                    OnbLine.Modify();
                    NextStart := OnbLine."Planned End Date" + 1;
                    Planned += 1;
                end;
            until OnbLine.Next() = 0;
        Message(PlanDatesMsg, Planned);
    end;

    /// <summary>
    /// The onboarding's lines for the Gantt chart: lineNo, description, indent, isGroup, start, end (yyyy-mm-dd), status.
    /// </summary>
    procedure GetGanttData(OnboardingCode: Code[20]): JsonArray
    var
        OnbLine: Record "Onb. Line";
        Lines: JsonArray;
        Line: JsonObject;
        StartDate: Date;
        EndDate: Date;
    begin
        if OnboardingCode = '' then
            exit(Lines);
        OnbLine.SetRange("Document Type", OnbLine."Document Type"::Onboarding);
        OnbLine.SetRange("Document Code", OnboardingCode);
        if OnbLine.FindSet() then
            repeat
                GetPlannedDates(OnbLine, StartDate, EndDate);
                Clear(Line);
                Line.Add('lineNo', OnbLine."Line No.");
                Line.Add('description', OnbLine.Description);
                Line.Add('indent', OnbLine.Indentation);
                Line.Add('isGroup', HasChildren(OnbLine));
                Line.Add('start', FormatIsoDate(StartDate));
                Line.Add('end', FormatIsoDate(EndDate));
                Line.Add('status', GetRollupStatus(OnbLine).AsInteger());
                Lines.Add(Line);
            until OnbLine.Next() = 0;
        exit(Lines);
    end;

    procedure CheckLearnUrl(Url: Text)
    begin
        if Url = '' then
            exit;
        if not LowerCase(Url).StartsWith(HttpsPrefixTxt) then
            Error(InvalidUrlErr, Url);
    end;

    /// <summary>
    /// Adds the selected templates to the onboarding as modules. A module that is already there only gets the
    /// template lines it is missing, each placed after the line copied from the template line before it.
    /// </summary>
    procedure CopyTemplates(var OnbTemplate: Record "Onb. Template"; OnboardingCode: Code[20])
    var
        Modules: Integer;
        Added: Integer;
        Present: Integer;
    begin
        if OnbTemplate.FindSet() then
            repeat
                CopyTemplate(OnbTemplate, OnboardingCode, Added, Present);
                Modules += 1;
            until OnbTemplate.Next() = 0;
        Message(CopyResultMsg, Modules, Added, Present);
    end;

    /// <summary>
    /// A free Line No. directly after AfterLineNo in the document.
    /// </summary>
    procedure GetLineNoAfter(DocumentType: Enum "Onb. Document Type"; DocumentCode: Code[20]; AfterLineNo: Integer): Integer
    var
        NextLine: Record "Onb. Line";
        NewLineNo: Integer;
    begin
        NextLine.SetRange("Document Type", DocumentType);
        NextLine.SetRange("Document Code", DocumentCode);
        NextLine.SetFilter("Line No.", '>%1', AfterLineNo);
        if not NextLine.FindFirst() then
            exit(AfterLineNo + LineNoStep());
        NewLineNo := AfterLineNo + (NextLine."Line No." - AfterLineNo) div 2;
        // shortcut: no automatic renumbering when a gap is used up; add it if users hit NoRoomErr.
        if NewLineNo = AfterLineNo then
            Error(NoRoomErr, AfterLineNo);
        exit(NewLineNo);
    end;

    procedure GetLastLineNo(DocumentType: Enum "Onb. Document Type"; DocumentCode: Code[20]): Integer
    var
        LastLine: Record "Onb. Line";
    begin
        LastLine.SetRange("Document Type", DocumentType);
        LastLine.SetRange("Document Code", DocumentCode);
        if LastLine.FindLast() then
            exit(LastLine."Line No.");
        exit(0);
    end;

    local procedure CopyTemplate(OnbTemplate: Record "Onb. Template"; OnboardingCode: Code[20]; var Added: Integer; var Present: Integer)
    var
        SourceLine: Record "Onb. Line";
        ModuleLine: Record "Onb. Line";
        ExistingLine: Record "Onb. Line";
        NewLine: Record "Onb. Line";
        NullGuid: Guid;
        LastPlacedLineNo: Integer;
    begin
        ModuleLine.SetRange("Document Type", ModuleLine."Document Type"::Onboarding);
        ModuleLine.SetRange("Document Code", OnboardingCode);
        ModuleLine.SetRange("Template Code", OnbTemplate.Code);
        ModuleLine.SetRange("Template Line ID", NullGuid);
        if ModuleLine.FindFirst() then
            LastPlacedLineNo := ModuleLine."Line No."
        else begin
            ModuleLine.Init();
            ModuleLine."Document Type" := ModuleLine."Document Type"::Onboarding;
            ModuleLine."Document Code" := OnboardingCode;
            ModuleLine."Line No." := GetLastLineNo(ModuleLine."Document Type", OnboardingCode) + LineNoStep();
            ModuleLine.Description := OnbTemplate.Description;
            ModuleLine."Learn URL" := OnbTemplate."Learn URL";
            ModuleLine."Template Code" := OnbTemplate.Code;
            ModuleLine.Insert(true);
            LastPlacedLineNo := ModuleLine."Line No.";
        end;

        SourceLine.SetRange("Document Type", SourceLine."Document Type"::Template);
        SourceLine.SetRange("Document Code", OnbTemplate.Code);
        if SourceLine.FindSet() then
            repeat
                ExistingLine.SetRange("Document Type", ExistingLine."Document Type"::Onboarding);
                ExistingLine.SetRange("Document Code", OnboardingCode);
                ExistingLine.SetRange("Template Code", OnbTemplate.Code);
                ExistingLine.SetRange("Template Line ID", SourceLine.SystemId);
                if ExistingLine.FindFirst() then begin
                    LastPlacedLineNo := ExistingLine."Line No.";
                    Present += 1;
                end else begin
                    NewLine.Init();
                    NewLine."Document Type" := NewLine."Document Type"::Onboarding;
                    NewLine."Document Code" := OnboardingCode;
                    NewLine."Line No." := GetLineNoAfter(NewLine."Document Type", OnboardingCode, LastPlacedLineNo);
                    NewLine.Description := SourceLine.Description;
                    NewLine.Type := SourceLine.Type;
                    NewLine."Duration (Days)" := SourceLine."Duration (Days)";
                    NewLine.Indentation := SourceLine.Indentation + 1;
                    NewLine.Instructions := SourceLine.Instructions;
                    NewLine."Learn URL" := SourceLine."Learn URL";
                    NewLine."Task Code" := SourceLine."Task Code";
                    NewLine."Template Code" := OnbTemplate.Code;
                    NewLine."Template Line ID" := SourceLine.SystemId;
                    NewLine.Insert(true);
                    LastPlacedLineNo := NewLine."Line No.";
                    Added += 1;
                end;
            until SourceLine.Next() = 0;
    end;

    local procedure ShiftBlock(var OnbLine: Record "Onb. Line"; Delta: Integer)
    var
        BlockLine: Record "Onb. Line";
    begin
        FilterDocument(BlockLine, OnbLine);
        BlockLine.SetRange("Line No.", OnbLine."Line No.", GetBlockEnd(OnbLine));
        if Delta > 0 then begin
            BlockLine.SetFilter(Indentation, '>=%1', 9);
            if not BlockLine.IsEmpty() then
                Error(CannotIndentErr);
            BlockLine.SetRange(Indentation);
        end;
        if BlockLine.FindSet(true) then
            repeat
                BlockLine.Indentation += Delta;
                BlockLine.Modify();
            until BlockLine.Next() = 0;
        OnbLine.Get(OnbLine."Document Type", OnbLine."Document Code", OnbLine."Line No.");
    end;

    // A line in FromLineNo..ToLineNo is a task (leaf) when the line after it is not deeper.
    local procedure CountLeaves(DocumentLine: Record "Onb. Line"; FromLineNo: Integer; ToLineNo: Integer; var Leaves: Integer; var Completed: Integer; var NotApplicable: Integer; var NotStarted: Integer)
    var
        RangeLine: Record "Onb. Line";
        PreviousLine: Record "Onb. Line";
        HasPrevious: Boolean;
    begin
        FilterDocument(RangeLine, DocumentLine);
        RangeLine.SetRange("Line No.", FromLineNo, ToLineNo);
        if RangeLine.FindSet() then
            repeat
                if HasPrevious and (RangeLine.Indentation <= PreviousLine.Indentation) then
                    TallyLeaf(PreviousLine, Leaves, Completed, NotApplicable, NotStarted);
                PreviousLine := RangeLine;
                HasPrevious := true;
            until RangeLine.Next() = 0;
        if HasPrevious then
            TallyLeaf(PreviousLine, Leaves, Completed, NotApplicable, NotStarted);
    end;

    local procedure TallyLeaf(LeafLine: Record "Onb. Line"; var Leaves: Integer; var Completed: Integer; var NotApplicable: Integer; var NotStarted: Integer)
    begin
        Leaves += 1;
        case LeafLine.Status of
            LeafLine.Status::Completed:
                Completed += 1;
            LeafLine.Status::"Not Applicable":
                NotApplicable += 1;
            LeafLine.Status::"Not Started":
                NotStarted += 1;
        end;
    end;

    local procedure AddToOrder(var RangeLine: Record "Onb. Line"; FromLineNo: Integer; ToLineNo: Integer; var TempOrderedLine: Record "Onb. Line" temporary; var Ids: List of [Guid])
    begin
        RangeLine.SetRange("Line No.", FromLineNo, ToLineNo);
        if RangeLine.FindSet() then
            repeat
                TempOrderedLine := RangeLine;
                TempOrderedLine."Line No." := Ids.Count() + 1;
                TempOrderedLine.Insert();
                Ids.Add(RangeLine.SystemId);
            until RangeLine.Next() = 0;
    end;

    local procedure FindNextLine(OnbLine: Record "Onb. Line"; var NextLine: Record "Onb. Line"): Boolean
    begin
        FilterDocument(NextLine, OnbLine);
        NextLine.SetFilter("Line No.", '>%1', OnbLine."Line No.");
        exit(NextLine.FindFirst());
    end;

    local procedure FilterDocument(var DocumentLine: Record "Onb. Line"; OnbLine: Record "Onb. Line")
    begin
        DocumentLine.Reset();
        DocumentLine.SetRange("Document Type", OnbLine."Document Type");
        DocumentLine.SetRange("Document Code", OnbLine."Document Code");
    end;

    local procedure FormatIsoDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        // Format 9 is the XML format: yyyy-mm-dd.
        exit(Format(Value, 0, 9));
    end;

    local procedure LineNoStep(): Integer
    begin
        exit(10000);
    end;
}
