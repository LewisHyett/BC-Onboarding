codeunit 80001 "Onb. Std. Templates"
{
    Access = Internal;

    var
        LearnBaseTxt: Label 'https://learn.microsoft.com/en-us/dynamics365/business-central/', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Onb. Template Registry", 'OnRegisterTemplates', '', false, false)]
    local procedure RegisterNfpFinanceTemplates(var Registry: Codeunit "Onb. Template Registry")
    begin
        RegisterGeneralLedger(Registry);
        RegisterDimensions(Registry);
        RegisterBudgets(Registry);
        RegisterPayables(Registry);
        RegisterReceivables(Registry);
        RegisterBank(Registry);
        RegisterFixedAssets(Registry);
        RegisterVat(Registry);
        RegisterReporting(Registry);
    end;

    local procedure RegisterGeneralLedger(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('GL', 'General ledger', 10, LearnBaseTxt + 'finance') then
            exit;
        Registry.AddTemplateTask('GL', '', 'GL-10', 'Chart of accounts', "Onb. Task Type"::Read,
            'Review how the chart of accounts is structured for fund accounting.', LearnBaseTxt + 'finance-setup-chart-accounts');
        Registry.AddTemplateTask('GL', 'GL-10', 'GL-11', 'Account types, categories and totalling for fund accounting', "Onb. Task Type"::Read,
            'Read how account types, account categories and totalling ranges work. Note how they map to your restricted and unrestricted funds.', LearnBaseTxt + 'finance-setup-chart-accounts');
        Registry.AddTemplateTask('GL', 'GL-10', 'GL-12', 'Create a G/L account for a new restricted fund', "Onb. Task Type"::Test,
            'In a test company, create a G/L account for a new restricted fund with the right category and totalling. Check it appears in the chart of accounts.', LearnBaseTxt + 'finance-setup-chart-accounts');
        Registry.AddTemplateTask('GL', '', 'GL-20', 'General journals', "Onb. Task Type"::Read,
            'Learn how general journals are used to post directly to the general ledger.', LearnBaseTxt + 'ui-work-general-journals');
        Registry.AddTemplateTask('GL', 'GL-20', 'GL-21', 'Journal templates and batches', "Onb. Task Type"::Read,
            'Read how journal templates and batches organise journal entries, and decide which batches your team needs.', LearnBaseTxt + 'ui-work-general-journals');
        Registry.AddTemplateTask('GL', 'GL-20', 'GL-22', 'Post a journal with fund and grant dimensions', "Onb. Task Type"::Test,
            'Post a general journal line that carries fund and grant dimension values. Check the dimensions on the posted G/L entries.', LearnBaseTxt + 'finance-how-post-transactions-directly');
        Registry.AddTemplateTask('GL', 'GL-20', 'GL-23', 'Reverse a posted journal', "Onb. Task Type"::Test,
            'Reverse the journal you posted and confirm the reversing entries cancel the original ones.', LearnBaseTxt + 'finance-how-reverse-journal-posting');
    end;

    local procedure RegisterDimensions(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('DIM', 'Funds, grants and dimensions', 20, LearnBaseTxt + 'finance-dimensions') then
            exit;
        Registry.AddTemplateTask('DIM', '', 'DIM-10', 'How dimensions track funds, grants and programmes', "Onb. Task Type"::Read,
            'Read how dimensions tag transactions. Agree which dimensions will hold funds, grants and programmes.', LearnBaseTxt + 'finance-dimensions');
        Registry.AddTemplateTask('DIM', '', 'DIM-20', 'Set default fund dimensions on G/L accounts', "Onb. Task Type"::Test,
            'Set default dimension values on fund-specific G/L accounts and post a test entry to check they are applied.', LearnBaseTxt + 'finance-dimensions');
        Registry.AddTemplateTask('DIM', '', 'DIM-30', 'Analyse expenditure by fund and programme', "Onb. Task Type"::Test,
            'Use an analysis view or G/L entries filtered by dimension to report expenditure by fund and programme.', LearnBaseTxt + 'finance-dimensions');
    end;

    local procedure RegisterBudgets(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('BUD', 'Budgets and allocations', 30, LearnBaseTxt + 'finance-how-create-budgets') then
            exit;
        Registry.AddTemplateTask('BUD', '', 'BUD-10', 'Budgets', "Onb. Task Type"::Read,
            'Learn how G/L budgets are created and compared with actuals.', LearnBaseTxt + 'finance-how-create-budgets');
        Registry.AddTemplateTask('BUD', 'BUD-10', 'BUD-11', 'G/L budgets with dimensions', "Onb. Task Type"::Read,
            'Read how budget dimensions let you budget per fund, grant or programme.', LearnBaseTxt + 'finance-how-create-budgets');
        Registry.AddTemplateTask('BUD', 'BUD-10', 'BUD-12', 'Create a grant budget and compare it with actuals', "Onb. Task Type"::Test,
            'Create a G/L budget for one grant using its dimension value. Compare it with actual postings.', LearnBaseTxt + 'finance-how-create-budgets');
        Registry.AddTemplateTask('BUD', '', 'BUD-20', 'Cost allocations', "Onb. Task Type"::Read,
            'Learn how allocation accounts spread costs and revenue across accounts and dimensions.', LearnBaseTxt + 'finance-allocate-revenue-costs');
        Registry.AddTemplateTask('BUD', 'BUD-20', 'BUD-21', 'Fixed and variable allocation accounts', "Onb. Task Type"::Read,
            'Read the difference between fixed and variable allocation accounts and pick the right one for support costs.', LearnBaseTxt + 'finance-allocate-revenue-costs');
        Registry.AddTemplateTask('BUD', 'BUD-20', 'BUD-22', 'Allocate shared support costs across programmes', "Onb. Task Type"::Test,
            'Set up an allocation account and post a shared support cost. Check how it is split across programme dimensions.', LearnBaseTxt + 'finance-allocate-revenue-costs');
        Registry.AddTemplateTask('BUD', '', 'BUD-30', 'Deferring multi-period grant income', "Onb. Task Type"::Read,
            'Read how deferral templates spread income or expenses over several periods, for example a multi-year grant.', LearnBaseTxt + 'finance-how-defer-revenue-expenses');
    end;

    local procedure RegisterPayables(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('AP', 'Payables', 40, LearnBaseTxt + 'payables-manage-payables') then
            exit;
        Registry.AddTemplateTask('AP', '', 'AP-10', 'Vendor setup', "Onb. Task Type"::Read,
            'Read how vendors are registered, including posting groups and payment terms.', LearnBaseTxt + 'purchasing-how-register-new-vendors');
        Registry.AddTemplateTask('AP', '', 'AP-20', 'Post a purchase invoice with fund dimensions', "Onb. Task Type"::Test,
            'Create and post a purchase invoice with fund dimension values. Check the dimensions on the vendor and G/L entries.', LearnBaseTxt + 'purchasing-how-record-purchases');
        Registry.AddTemplateTask('AP', '', 'AP-30', 'Vendor payments', "Onb. Task Type"::Read,
            'Learn the options for paying vendors.', LearnBaseTxt + 'payables-make-payments');
        Registry.AddTemplateTask('AP', 'AP-30', 'AP-31', 'Suggest and post vendor payments', "Onb. Task Type"::Test,
            'Use Suggest Vendor Payments in a payment journal and post the result.', LearnBaseTxt + 'payables-how-suggest-vendor-payments');
        Registry.AddTemplateTask('AP', 'AP-30', 'AP-32', 'Apply a payment to an invoice manually', "Onb. Task Type"::Test,
            'Post a payment without applying it, then apply it to the open invoice from the vendor ledger entries.', LearnBaseTxt + 'payables-how-apply-purchase-transactions-manually');
    end;

    local procedure RegisterReceivables(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('AR', 'Receivables, donors and funders', 50, LearnBaseTxt + 'receivables-manage-receivables') then
            exit;
        Registry.AddTemplateTask('AR', '', 'AR-10', 'Set up donors and funders as customers', "Onb. Task Type"::Read,
            'Read how customers are registered, and agree how donors and funders will be set up as customers.', LearnBaseTxt + 'sales-how-register-new-customers');
        Registry.AddTemplateTask('AR', '', 'AR-20', 'Invoice a grant claim', "Onb. Task Type"::Test,
            'Create and post a sales invoice to a funder for a grant claim, with the grant dimension.', LearnBaseTxt + 'sales-how-invoice-sales');
        Registry.AddTemplateTask('AR', '', 'AR-30', 'Post and apply a receipt', "Onb. Task Type"::Test,
            'Post a cash receipt from the funder and apply it to the grant claim invoice.', LearnBaseTxt + 'receivables-how-apply-sales-transactions-manually');
        Registry.AddTemplateTask('AR', '', 'AR-40', 'Collect outstanding balances', "Onb. Task Type"::Read,
            'Read the tools for following up overdue balances, such as reminders and statements.', LearnBaseTxt + 'receivables-collect-outstanding-balances');
    end;

    local procedure RegisterBank(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('BANK', 'Cash management', 60, LearnBaseTxt + 'bank-manage-bank-accounts') then
            exit;
        Registry.AddTemplateTask('BANK', '', 'BANK-10', 'Set up a bank account', "Onb. Task Type"::Test,
            'Create a bank account with its posting group and check it posts to the right G/L account.', LearnBaseTxt + 'bank-how-setup-bank-accounts');
        Registry.AddTemplateTask('BANK', '', 'BANK-20', 'Reconcile a bank account', "Onb. Task Type"::Test,
            'Run a bank account reconciliation against a sample statement and post it.', LearnBaseTxt + 'bank-how-reconcile-bank-accounts-separately');
    end;

    local procedure RegisterFixedAssets(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('FA', 'Fixed assets', 70, LearnBaseTxt + 'fa-manage') then
            exit;
        Registry.AddTemplateTask('FA', '', 'FA-10', 'Fixed asset setup and posting groups', "Onb. Task Type"::Read,
            'Read the general fixed asset setup and how FA posting groups link assets to G/L accounts.', LearnBaseTxt + 'fa-how-setup-general');
        Registry.AddTemplateTask('FA', '', 'FA-20', 'Depreciation books', "Onb. Task Type"::Read,
            'Read how depreciation books and methods are set up.', LearnBaseTxt + 'fa-how-setup-depreciation');
        Registry.AddTemplateTask('FA', '', 'FA-30', 'Acquire a fixed asset', "Onb. Task Type"::Test,
            'Create a fixed asset and post its acquisition cost. Check the FA ledger and G/L entries.', LearnBaseTxt + 'fa-how-acquire');
    end;

    local procedure RegisterVat(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('VAT', 'VAT', 80, LearnBaseTxt + 'finance-setup-vat') then
            exit;
        Registry.AddTemplateTask('VAT', '', 'VAT-10', 'VAT setup, including exempt and partially exempt activity', "Onb. Task Type"::Read,
            'Read how VAT posting groups and setup work. Note how exempt and partially exempt activity will be handled.', LearnBaseTxt + 'finance-setup-vat');
        Registry.AddTemplateTask('VAT', '', 'VAT-20', 'Prepare a VAT return', "Onb. Task Type"::Test,
            'Create a VAT return for a test period, suggest the lines and review the figures.', LearnBaseTxt + 'finance-how-report-vat');
    end;

    local procedure RegisterReporting(var Registry: Codeunit "Onb. Template Registry")
    begin
        if not Registry.AddTemplateModule('REP', 'Reporting and year end', 90, LearnBaseTxt + 'bi') then
            exit;
        Registry.AddTemplateTask('REP', '', 'REP-10', 'Financial reporting', "Onb. Task Type"::Read,
            'Learn how financial reports are built from row and column definitions.', LearnBaseTxt + 'bi-how-work-account-schedule');
        Registry.AddTemplateTask('REP', 'REP-10', 'REP-11', 'Financial reports and account categories', "Onb. Task Type"::Read,
            'Read how financial reports use account categories, and which standard reports fit your needs.', LearnBaseTxt + 'bi-how-work-account-schedule');
        Registry.AddTemplateTask('REP', 'REP-10', 'REP-12', 'Run an income and expenditure report by fund', "Onb. Task Type"::Test,
            'Run an income and expenditure financial report filtered by the fund dimension and check the totals.', LearnBaseTxt + 'bi-how-work-account-schedule');
        Registry.AddTemplateTask('REP', 'REP-10', 'REP-13', 'Statistical accounts for non-financial measures', "Onb. Task Type"::Read,
            'Read how statistical accounts record non-financial figures, such as beneficiaries served, for use in reports.', LearnBaseTxt + 'bi-use-statistical-accounts');
        Registry.AddTemplateTask('REP', '', 'REP-20', 'Period and year-end close', "Onb. Task Type"::Read,
            'Learn the steps for closing periods and the fiscal year.', LearnBaseTxt + 'year-close-years-periods');
        Registry.AddTemplateTask('REP', 'REP-20', 'REP-21', 'Accounting periods and fiscal year close', "Onb. Task Type"::Read,
            'Read how accounting periods are created and how the fiscal year is closed.', LearnBaseTxt + 'year-close-years-periods');
        Registry.AddTemplateTask('REP', 'REP-20', 'REP-22', 'Run Close Income Statement in a test company', "Onb. Task Type"::Test,
            'In a test company, run Close Income Statement and post the resulting journal. Check the retained earnings balance.', LearnBaseTxt + 'year-close-years-periods');
    end;
}
