# High-Risk Files & Testing Mandate

## Testing Mandate for Cross-Cutting Changes

When a change has cross-cutting impact (anything flagged AFFECTED in the blast radius analysis), the following verification is REQUIRED:

1. **Aggregation correctness:** For any affected SUM/COUNT/AVG query, verify the result is correct with:
   - The original data (regression)
   - The new data pattern (e.g., 2 rows where there used to be 1)
   - Edge cases (0 rows, NULL values, mixed old/new data)

2. **View consistency:** If a view is affected, verify its output matches expectations with the new data.

3. **API response validation:** If an API response changes, verify:
   - Frontend components still render correctly
   - Mobile app can parse the response (if applicable)
   - External integrations handle the change (if applicable)

4. **PDF generation:** If product/cost/pricing data changes, generate a test PDF and verify it's correct.

5. **Quote policy evaluation:** If cost/margin inputs change, verify quote policies still evaluate correctly with the new values.

6. **Financial reporting smoke test:** After any change that touches financial data paths, verify:
   - Project revenue/costs/margins display correctly on project detail page
   - Actuals dashboard metrics are accurate
   - Monthly breakdown numbers make sense
   - Alert thresholds fire correctly

---

## High-Risk File Registry

These files have the highest blast radius in the codebase. Changes to these files should always trigger a thorough review:

| File | Risk Level | Reason |
|------|-----------|--------|
| `/internal/domain/dbclient/projects.go` | CRITICAL | Contains `product_agg_cte` — the financial aggregation core |
| `/internal/database/queries/actuals.sql` | CRITICAL | Contains ALL actuals/backlog/variance/alert queries |
| `/internal/domain/dbclient/actuals.go` | CRITICAL | Plant/project/customer performance summaries |
| `/internal/domain/dbclient/actuals_alerts.go` | HIGH | Volume variance and delay alert detection |
| `/internal/database/migrations/auto/v_projects.sql` | HIGH | Project view with revenue/cost aggregation |
| `/internal/database/migrations/auto/v_quotes.sql` | HIGH | Quote view with revenue aggregation |
| `/internal/database/migrations/auto/v_project_products.sql` | HIGH | Product cost computation via SQL functions |
| `/internal/database/migrations/auto/v_quote_products.sql` | HIGH | Product cost computation via SQL functions |
| `/internal/domain/quote_policy.go` | HIGH | 30+ approval threshold evaluations |
| `/internal/domain/pdf_input.go` | MEDIUM | PDF data assembly for quotes/projects |
| `/internal/apex/export.go` | MEDIUM | Quote export to Apex/JWS ERP |
| `/slab-core/src/hooks/useProductSection.ts` | MEDIUM | 42KB shared hook for product forms (projects + quotes) |
| `/slab-core/src/formik/projectOrQuoteProduct.ts` | MEDIUM | Shared Formik schema for product line items |
| `/internal/database/migrations/auto/calculate_*.sql` | MEDIUM | Cost calculation SQL functions used by views |
| `/internal/database/migrations/auto/margin.sql` | MEDIUM | Margin calculation SQL function |
| `/internal/database/migrations/auto/convert_units.sql` | MEDIUM | Unit conversion SQL function (known i18n issues) |
| `/internal/domain/dbclient/forecasts.go` | MEDIUM | Forecast aggregation queries |

<!-- Extracted from root CLAUDE.md on 2026-01-30: Sections 8-9 moved to on-demand reference doc -->
