namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy Customer Import Range (ID 30105).
/// </summary>
enum 30105 "Shpfy Customer Import Range"
{
    Caption = 'Shopify Customer Import Range';
    Extensible = false;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; WithOrderImport)
    {
        Caption = 'With Order Import';
    }
    value(2; AllCustomers)
    {
        Caption = 'All Customers';
    }
}
