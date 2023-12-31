namespace Microsoft.API.V1;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Integration.Graph;

page 20018 "APIV1 - G/L Entries"
{
    APIVersion = 'v1.0';
    Caption = 'generalLedgerEntries', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'generalLedgerEntry';
    EntitySetName = 'generalLedgerEntries';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "G/L Entry";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."Entry No.")
                {
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'postingDate', Locked = true;
                }
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'documentNumber', Locked = true;
                }
                field(documentType; Rec."Document Type")
                {
                    Caption = 'documentType', Locked = true;
                }
                field(accountId; Rec."Account Id")
                {
                    Caption = 'accountId', Locked = true;
                }
                field(accountNumber; Rec."G/L Account No.")
                {
                    Caption = 'accountNumber', Locked = true;
                }
                field(description; Rec.Description)
                {
                    Caption = 'description', Locked = true;
                }
                field(debitAmount; Rec."Debit Amount")
                {
                    Caption = 'debitAmount', Locked = true;
                }
                field(creditAmount; Rec."Credit Amount")
                {
                    Caption = 'creditAmount', Locked = true;
                }
                field(dimensions; DimensionsJSON)
                {
                    Caption = 'dimensions', Locked = true;
#pragma warning disable AL0667
                    ODataEDMType = 'Collection(DIMENSION)';
#pragma warning restore
                    ToolTip = 'Specifies Journal Line Dimensions.';
                }
                field(lastModifiedDateTime; Rec."Last Modified DateTime")
                {
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    var
        DimensionsJSON: Text;

    local procedure SetCalculatedFields()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        DimensionsJSON := GraphMgtComplexTypes.GetDimensionsJSON(Rec."Dimension Set ID");

    end;
}


