codeunit 139651 "HybridBC Wizard Tests"
{
    // [FEATURE] [Intelligent Edge Hybrid Business Central Wizard]
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        Initialized: Boolean;
        SqlServerTypeOption: Option SQLServer,AzureSQL;
        ProductNameTxt: Label 'Dynamics 365 Business Central current version (v.%1)', Locked = true;
        NoCompaniesSelectedMsg: Label 'You must select at least one company to replicate to continue.';

    local procedure Initialize(var HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard"; IsSaas: Boolean; CompanySelected: Boolean)
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
        HybridCompany: Record "Hybrid Company";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        HybridReplicationSummary.DeleteAll();
        HybridDeploymentSetup.DeleteAll();
        HybridDeploymentSetup."Handler Codeunit ID" := Codeunit::"Library - Hybrid Management";
        HybridDeploymentSetup.Insert();

        HybridDeploymentSetup.Get();

        if not Initialized then begin
            BindSubscription(LibraryHybridManagement);
            Initialized := true;
        end;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaas);
        AssistedSetupTestLibrary.CallOnRegister();
        AssistedSetupTestLibrary.SetStatusToNotCompleted(Page::"Hybrid Cloud Setup Wizard");
        HybridCloudSetupWizard.Trap();

        Page.Run(Page::"Hybrid Cloud Setup Wizard");

        HybridCloudSetupWizard.AgreePrivacy.SetValue(true);

        HybridCompany.DeleteAll();
        HybridCompany.Init();
        HybridCompany."Name" := 'TWO';
        HybridCompany."Display Name" := 'Fabrikam, Inc.';
        HybridCompany.Replicate := CompanySelected;
        HybridCompany.Insert();
    end;

    [Test]
    [HandlerFunctions('ProvidersBCPageHandler')]
    procedure TestSqlConfigurationWindow()
    var
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
        currentOption: Text;
        optionCount: Integer;
        sqlAzureTxt: Label 'Azure SQL';
        sqlServerTxt: Label 'SQL Server';
    begin
        // [SCENARIO] User starts wizard from saas environment and navigates to SQL Type window.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, true);
        optionCount := 1;
        // [GIVEN] User clicks 'Next' on Welcome window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [WHEN] User selects a product and clicks 'Next' on Dynamics Product window.
        HybridCloudSetupWizard."Product Name".AssistEdit();
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] SQL Configuration window is displayed and expected SQL types are listed.
        VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard);
        while optionCount <= HybridCloudSetupWizard."Sql Server Type".OptionCount() do begin
            currentOption := HybridCloudSetupWizard."Sql Server Type".GetOption(optionCount);

            case OptionCount of
                1:
                    Assert.AreEqual(sqlServerTxt, currentOption, 'Unexpected SqlType');
                2:
                    Assert.AreEqual(sqlAzureTxt, currentOption, 'Unexpected SqlType');
                else
                    Assert.Fail('SqlType out of range');
            end;

            OptionCount += 1;
        end;
    end;


    [Test]
    [HandlerFunctions('ProvidersBCPageHandler,ConfirmNoHandler')]
    procedure TestAzureSqlScheduleFlow()
    var
        GuidedExperience: Codeunit "Guided Experience";
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User starts wizard from saas environment and navigates the wizard selecting Azure SQL server.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, true);
        // [THEN] Welcome window is displayed.
        VerifySaasWelcomeWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Welcome window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Dynamics Product window is displayed.
        VerifySaasDynamicsProductWindow(HybridCloudSetupWizard);
        // [GIVEN] User selects Dynamics Business Central.
        HybridCloudSetupWizard."Product Name".AssistEdit();
        // [GIVEN] User clicks 'Next' on Dynamics Product window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] SQL Configuration window is displayed.
        VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard);
        // [WHEN] User selects Azure SQL.
        HybridCloudSetupWizard."Sql Server Type".SetValue(SqlServerTypeOption::AzureSql);
        // [GIVEN] Users sets a connection string.
        HybridCloudSetupWizard.SqlConnectionString.SetValue('someconnectionstring');
        // [GIVEN] User clicks 'Next' on SQL Configuration window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] ADF IR Runtime window is displayed.
        Assert.IsFalse(HybridCloudSetupWizard.DownloadShir.Visible(), 'ADF Instructions window Download Self Hosted Integration Runtime should not be visible.');
        // [THEN] Company Selection window is displayed.
        VerifyCompanySelectionWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Company Selection window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Done window is displayed.
        VerifySaasDoneWindow(HybridCloudSetupWizard, 1);
        // [GIVEN] User clicks 'Finish' on Done window.
        HybridCloudSetupWizard.ActionFinish.Invoke();
        // [THEN] Status of assisted setup remains not completed.
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Hybrid Cloud Setup Wizard"), 'Wizard status should be completed.');
    end;

    [Test]
    [HandlerFunctions('ProvidersBCPageHandler')]
    procedure TestLocalSqlNextAndBackFlows()
    var
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User navigates the wizard selecting Local SQL server and clicks back on done window to verify correct windows are displayed.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, true);
        // [THEN] Welcome window is displayed.
        VerifySaasWelcomeWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Welcome window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Dynamics Product window is displayed.
        VerifySaasDynamicsProductWindow(HybridCloudSetupWizard);
        // [GIVEN] User selects Dynamics Business Central.
        HybridCloudSetupWizard."Product Name".AssistEdit();
        // [GIVEN] User clicks 'Next' on Dynamics Product window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] SQL Configuration window is displayed.
        VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard);
        // [GIVEN] User selects Local SQL.
        HybridCloudSetupWizard."Sql Server Type".SetValue(SqlServerTypeOption::SQLServer);
        // [GIVEN] User enters connection string.
        HybridCloudSetupWizard.SqlConnectionString.SetValue('someconnectionstring');
        // [GIVEN] User clicks 'Next' on SQL Configuration window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] ADF IR Runtime window is displayed.
        VerifySaasIRInstructionsWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on ADF Information window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Company Selection window is displayed.
        VerifyCompanySelectionWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Company Selection window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Done window is displayed.
        VerifySaasDoneWindow(HybridCloudSetupWizard, 1);
        // [GIVEN] User clicks 'Back' on Done window.
        HybridCloudSetupWizard.ActionBack.Invoke();
        // [GIVEN] User clicks 'Back' on ADF Instructions window.
        HybridCloudSetupWizard.ActionBack.Invoke();
    end;

    [Test]
    [HandlerFunctions('ProvidersBCPageHandler,ConfirmNoHandler')]
    procedure TestExistingIntegrationRuntime()
    var
        GuidedExperience: Codeunit "Guided Experience";
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User navigates the wizard and enters an existing Runtime Name to verify correct windows are displayed.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, true);

        with HybridCloudSetupWizard do begin
            // [THEN] Welcome window is displayed.
            VerifySaasWelcomeWindow(HybridCloudSetupWizard);
            // [GIVEN] User clicks 'Next' on Welcome window.
            ActionNext.Invoke();

            // [THEN] Dynamics Product window is displayed.
            VerifySaasDynamicsProductWindow(HybridCloudSetupWizard);
            // [GIVEN] User selects Dynamics Business Central.
            "Product Name".AssistEdit();

            // [GIVEN] User clicks 'Next' on Dynamics Product window.
            ActionNext.Invoke();

            // [THEN] SQL Configuration window is displayed.
            VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard);
            // [GIVEN] User selects SQL Server.
            "Sql Server Type".SetValue(SqlServerTypeOption::SQLServer);

            // [GIVEN] User sets a connection string.
            SqlConnectionString.SetValue('someconnectionstring');

            // [GIVEN] User sets an existing runtime name.
            RuntimeName.SetValue('someexistingruntimename');

            // [GIVEN] User clicks 'Next' on SQL Configuration window.
            ActionNext.Invoke();

            // [THEN] ADF Instructions window should not be displayed.
            Assert.IsFalse(DownloadShir.Visible(), 'ADF Instructions window should not be displayed.');

            // [THEN] Company Selection window is displayed.
            VerifyCompanySelectionWindow(HybridCloudSetupWizard);

            // [GIVEN] User clicks 'Next' on Company Selection window.
            ActionNext.Invoke();

            // [THEN] Done window is displayed
            VerifySaasDoneWindow(HybridCloudSetupWizard, 1);

            // [GIVEN] User clicks 'Finish' on Done window.
            ActionFinish.Invoke();

            // [THEN] Status of assisted setup is completed.
            Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Hybrid Cloud Setup Wizard"), 'Wizard status should be completed.');
        end;
    end;

    [Test]
    [HandlerFunctions('ProvidersBCPageHandler,ConfirmYesHandler')]
    procedure TestNoCompanyMessage()
    var
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User navigates the wizard selecting Local SQL server and clicks back on done window to verify correct windows are displayed.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, false);
        // [THEN] Welcome window is displayed.
        VerifySaasWelcomeWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Welcome window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Dynamics Product window is displayed.
        VerifySaasDynamicsProductWindow(HybridCloudSetupWizard);
        // [GIVEN] User selects Dynamics Business Central.
        HybridCloudSetupWizard."Product Name".AssistEdit();
        // [GIVEN] User clicks 'Next' on Dynamics Product window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] SQL Configuration window is displayed.
        VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard);
        // [GIVEN] User selects Local SQL.
        HybridCloudSetupWizard."Sql Server Type".SetValue(SqlServerTypeOption::SQLServer);
        // [GIVEN] User enters connection string.
        HybridCloudSetupWizard.SqlConnectionString.SetValue('someconnectionstring');
        // [GIVEN] User clicks 'Next' on SQL Configuration window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] ADF IR Runtime window is displayed.
        VerifySaasIRInstructionsWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on ADF Information window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Company Selection window is displayed.
        VerifyCompanySelectionWindow(HybridCloudSetupWizard);
        // [GIVEN] Deselect all companies
        HybridCloudSetupWizard.SelectAll.SetValue(false);
        // [GIVEN] User clicks 'Next' on Company Selection window.
        asserterror HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] User gets a message to select at least one company.
        Assert.ExpectedError(NoCompaniesSelectedMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TestNoProductSelectedError()
    var
        HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User navigates the wizard selecting Local SQL server and clicks back on done window to verify correct windows are displayed.

        // [GIVEN] User starts the wizard.
        Initialize(HybridCloudSetupWizard, true, false);
        // [THEN] Welcome window is displayed.
        VerifySaasWelcomeWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Welcome window.
        HybridCloudSetupWizard.ActionNext.Invoke();
        // [THEN] Dynamics Product window is displayed.
        VerifySaasDynamicsProductWindow(HybridCloudSetupWizard);
        // [GIVEN] User clicks 'Next' on Dynamics Product window.
        asserterror HybridCloudSetupWizard.ActionNext.Invoke();
    end;

    local procedure VerifySaasWelcomeWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard")
    begin
        Assert.IsFalse(HybridCloudSetupWizard.ActionBack.Enabled(), 'Welcome window ActionBack should be disabled.');
        Assert.IsTrue(HybridCloudSetupWizard.ActionNext.Enabled(), 'Welcome window ActionNext should be enabled.');
        Assert.IsFalse(HybridCloudSetupWizard.ActionFinish.Enabled(), 'Welcome window ActionFinish should be disabled.');
    end;

    local procedure VerifySaasDynamicsProductWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard")
    begin
        Assert.IsTrue(HybridCloudSetupWizard.ActionBack.Enabled(), 'Dynamics Product window ActionBack should be enabled.');
        Assert.IsTrue(HybridCloudSetupWizard.ActionNext.Enabled(), 'Dynamics Product window ActionNext should be enabled.');
        Assert.IsFalse(HybridCloudSetupWizard.ActionFinish.Enabled(), 'Dynamics Product window ActionFinish should be disabled.');
    end;

    local procedure VerifySaasSqlConfigurationWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard")
    begin
        Assert.IsTrue(HybridCloudSetupWizard.ActionBack.Enabled(), 'SQL Type window ActionBack should be enabled.');
        Assert.IsTrue(HybridCloudSetupWizard.ActionNext.Enabled(), 'SQL Type window ActionNext should be enabled.');
        Assert.IsFalse(HybridCloudSetupWizard.ActionFinish.Enabled(), 'SQL Type window ActionFinish should be disabled.');
    end;

    local procedure VerifySaasIRInstructionsWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard")
    begin
        Assert.IsTrue(HybridCloudSetupWizard.ActionBack.Enabled(), 'ADF Info window ActionBack should be enabled.');
        Assert.IsTrue(HybridCloudSetupWizard.ActionNext.Enabled(), 'ADF Info window ActionNext should be enabled.');
        Assert.IsFalse(HybridCloudSetupWizard.ActionFinish.Enabled(), 'ADF Info window ActionFinish should be disabled.');
        Assert.IsTrue(HybridCloudSetupWizard.DownLoadShir.Visible(), 'ADF Instructions window Download Self Hosted Integration Runtime should be visible.');
    end;

    local procedure VerifyCompanySelectionWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard")
    begin
        Assert.IsTrue(HybridCloudSetupWizard.ActionBack.Enabled(), 'ADF Connection window ActionBack should be enabled.');
        Assert.IsTrue(HybridCloudSetupWizard.ActionNext.Enabled(), 'ADF Connection window ActionNext should be enabled.');
        Assert.IsFalse(HybridCloudSetupWizard.ActionFinish.Enabled(), 'ADF Connection window ActionFinish should be disabled.');
    end;

    local procedure VerifySaasDoneWindow(HybridCloudSetupWizard: TestPage "Hybrid Cloud Setup Wizard"; executeNumber: Integer)
    begin
        Assert.IsTrue(HybridCloudSetupWizard.ActionBack.Enabled(), StrSubstNo('Done window ActionBack should be enabled. Run %1', executeNumber));
        Assert.IsFalse(HybridCloudSetupWizard.ActionNext.Enabled(), StrSubstNo('Done window ActionNext should be disabled. Run %1', executeNumber));
        Assert.IsTrue(HybridCloudSetupWizard.ActionFinish.Enabled(), StrSubstNo('Done window ActionFinish should be enabled. Run %1', executeNumber));
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(question: Text[1024]; var reply: Boolean)
    begin
        reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(question: Text[1024]; var reply: Boolean)
    begin
        reply := false;
    end;


    [ModalPageHandler]
    procedure ProvidersBCPageHandler(var HybridProductTypes: TestPage "Hybrid Product Types")
    begin
        HybridProductTypes.FindFirstField("Display Name", GetProductName());
        HybridProductTypes.OK().Invoke();
    end;

    local procedure GetProductName(): Text
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(StrSubstNo(ProductNameTxt, CurrentModuleInfo.AppVersion.Major));
    end;
}
