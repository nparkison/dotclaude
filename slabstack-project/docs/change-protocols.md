# Change-Type-Specific Protocols

These protocols define the exact steps to follow when making specific types of changes. Use the appropriate protocol based on the type of change you're implementing.

---

## When Modifying Database Schema

1. **Search for ALL queries that touch the affected table:**
   ```bash
   grep -rn "<table_name>" internal/database/queries/ internal/domain/dbclient/ --include="*.go" --include="*.sql"
   ```
2. **Search for ALL views that depend on the affected table:**
   ```bash
   grep -rn "<table_name>" internal/database/migrations/auto/v_*.sql
   ```
3. **Search for ALL SQL functions that reference the affected table:**
   ```bash
   grep -rn "<table_name>" internal/database/migrations/auto/calculate_*.sql internal/database/migrations/auto/margin.sql internal/database/migrations/auto/convert_units.sql
   ```
4. **Check foreign key chains:** What tables reference this table? What tables do THIS table reference? Trace both directions.
5. **If adding columns:** Do any existing queries use `SELECT *`? They will pick up new columns automatically — is that safe?
6. **If changing cardinality (1:1 → 1:N):** This is the HIGHEST RISK change. You MUST check every SUM, COUNT, AVG, and GROUP BY query that touches the table. Each aggregation must remain correct with the new row count.

## When Modifying Data Cardinality

**THIS IS THE CHANGE THAT NEARLY BROKE EVERYTHING.** When the meaning of "one row" changes:

1. **List every aggregation query** that touches the affected table (use searches above).
2. **For each aggregation:** Will the result change with more/fewer rows? If yes, the query needs updating or the data model needs a safety mechanism.
3. **Check downstream of aggregations:** What consumes the aggregated result? Trace the full critical path.
4. **Document the safety mechanism:** How are downstream consumers protected? (e.g., additional rows have `quantity = 0` to preserve SUM correctness)

## When Modifying API Response Shapes

1. **Search for frontend consumers:**
   ```bash
   grep -rn "<field_name>\|<TypeName>" slab-core/src/types/api/ slab-web/src/ --include="*.ts" --include="*.tsx"
   ```
2. **Search for mobile consumers:**
   ```bash
   grep -rn "<field_name>\|<TypeName>" slab-mobile/src/ --include="*.ts" --include="*.tsx"
   ```
3. **Check Apex/Connect/Series export mappings:** Do external systems consume this field?
4. **Check PDF generation:** Does `pdf_input.go` reference this field?
5. **If removing or renaming a field:** This is a breaking change for mobile. Mobile releases lag behind web — the old mobile version will still expect the old field name.

## When Modifying Shared UI Components or Hooks

1. **Search for all consumers:**
   ```bash
   grep -rn "import.*<ComponentName>\|from.*<file_path>" slab-web/src/ slab-core/src/ --include="*.ts" --include="*.tsx"
   ```
2. **`useProductSection.ts` is the highest-risk shared hook** — it's 42KB and shared between project drawer AND quote drawer. Changes here affect both.
3. **`projectOrQuoteProduct.ts` (Formik schema)** is shared between projects and quotes. Changes affect both forms.
4. **DataTable components** are used on every list page. Changes affect every list.

## When Modifying Business Logic (Pricing, Margins, Costs)

1. **Trace the cost calculation chain:**
   - Material cost: `Material.in_product_cost` → via `CostRule.apply()` → stored on material
   - Other cost: `Product.other_cost` → via `calculate_other_cost_amount()` SQL function → uses ReadyMixConstants
   - Delivery cost: `DeliveryCost` → via trigger `delivery_cost_calculations_tgr` → stored on delivery_costs row
   - Total cost: `material_cost + other_cost + delivery_cost` (per unit) × quantity
2. **Check quote policy thresholds:** `/internal/domain/quote_policy.go` has 30+ threshold types that evaluate margins, quantities, and prices. Any change to cost inputs changes which policies are violated.
3. **Check margin display:** Frontend margin calculations in TypeScript types (`QuoteProduct.ts`, `ProjectProduct.ts`) must match backend calculations.
4. **Check PDF output:** `pdf_input.go` formats costs/margins for display — any new cost component must be included.

## When Modifying Enums or Type Values

1. **Search for all usage of the enum:**
   ```bash
   grep -rn "<EnumValue>" internal/ slab-core/ slab-web/ --include="*.go" --include="*.ts" --include="*.tsx" --include="*.sql"
   ```
2. **Check database CHECK constraints:** Some columns have CHECK constraints on valid values.
3. **Check frontend dropdowns:** Enum values populate select/dropdown options.
4. **Check SQL CASE statements:** Many queries use `CASE WHEN category = 'Mix'` etc.
5. **Check external system mappings:** Apex/Connect may map enum values to external codes.

## When Modifying Permissions or Access Control

1. **Check middleware stack:** `/internal/roles/middleware.go` and `/internal/scopes/middleware.go`
2. **Check domain type scopes:** Each entity has a `DomainType` (e.g., `DomainTypeQuotes`, `DomainTypeCompanies`). Users need read/write scopes for each.
3. **Check mobile access:** Mobile app uses the same auth — permission changes affect mobile.
4. **Check report visibility:** Dashboard roles control which dashboards users see.
5. **Check feature flags:** Some features are gated by tenant-level feature flags (e.g., `FeatureFlagMultiTruckingEnabled`, `FeatureFlagActualsDashboard`).

---

## Cardinality Safety Rules

These rules specifically prevent the class of bug that nearly shipped with multi-truck.

1. **When adding rows to `project_products` or `quote_products` for the same logical product:** Additional rows MUST have `quantity = 0` and `price_amount = 0`. Only the primary row carries the real quantity and price. This preserves all existing SUM queries.

2. **When deleting a quantity-bearing row while siblings remain:** Transfer `quantity` and `price_amount` to the next remaining sibling row BEFORE deletion.

3. **When designing any feature that changes the "one row = one X" assumption for ANY table:** Perform a dedicated cardinality impact analysis (see blast-radius-guide.md, Section 4, Step 6 specifically).

4. **Never assume a table's row count is stable.** Before writing any `SUM`, `COUNT`, or `AVG` query, explicitly consider: "What happens if there are 2 rows where I expected 1?"

<!-- Extracted from root CLAUDE.md on 2026-01-30: Sections 6-7 moved to on-demand reference doc -->
