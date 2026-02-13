# Cross-Cutting Impact Analysis — Blast Radius Guide

> **Origin:** On 2026-01-30, we nearly shipped a multi-truck feature that would have silently doubled every financial metric in the system. 16 stories were planned, built, and code-reviewed before anyone realized the core data model assumption (1 row = 1 product per project) was baked into every revenue, cost, volume, and forecasting query. This was caught by accident during a client feedback session — not during planning, grooming, development, or code review.
>
> **These rules exist to ensure that NEVER happens again — for ANY change, not just financial ones.**

## When This Guide Applies

You MUST follow these rules whenever a proposed change touches ANY of the following:

- Database schema (new tables, columns, constraints, triggers, views)
- Data cardinality (1:1 becoming 1:N, new rows for existing entities, changing what a "row" represents)
- API response shape (added/removed/renamed fields, changed types, new endpoints)
- Shared components or hooks (UI components used on multiple pages)
- Enums, types, or domain model changes
- Business logic (pricing, margins, tax, delivery costs, volume calculations)
- Aggregation queries (anything with SUM, COUNT, AVG, GROUP BY)
- Permission or access control changes
- Integration touchpoints (Apex, Series, Sysdyne, Connect, BCMI)
- PDF generation data or templates

---

## 1. Entity Dependency Map

Before making changes, understand what depends on the entity you're modifying. This map covers the major entities and their downstream consumers.

### `project_products` — CRITICAL (Highest Blast Radius)

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **product_agg_cte** | `/internal/domain/dbclient/projects.go:170-227` | `SUM(price_amount * quantity)` for revenue, `SUM(cost * quantity)` for costs, `SUM(products.quantity * quantity)` for volume | Row cardinality changes (more rows = inflated sums) |
| **v_projects view** | `/internal/database/migrations/auto/v_projects.sql` | Revenue, total costs, estimated volume, category-specific quantities | Same as above — aggregates project_products per project_id |
| **v_project_products view** | `/internal/database/migrations/auto/v_project_products.sql` | Per-unit cost calculations via `calculate_other_cost_amount()`, `margin()`, delivery cost functions | Cost function inputs change, delivery_costs_id changes |
| **Actuals project breakdown** | `/internal/domain/dbclient/actuals.go:417-501` | `SUM(qp.quantity)` grouped by product_id for quoted volume | Row duplication inflates quoted volume |
| **Forecast comparison** | `/internal/domain/dbclient/forecasts.go` | Compares forecast values against project product quantities | Inflated quantities create false variance |
| **PDF generation** | `/internal/server/pdfgeneratorapi.go` + `/internal/domain/pdf_input.go` | Iterates products to build PDF line items | New rows create duplicate line items in PDFs |
| **Apex/Connect export** | `/internal/apex/products.go`, `/internal/connect/` | Exports product data to external systems | Duplicate rows exported, external system confused |
| **Frontend Project Drawer** | `/slab-core/src/hooks/useProductSection.ts` | Manages product line items in Formik state | Array shape changes break form indexing |
| **Frontend TypeScript types** | `/slab-core/src/types/api/ProjectProduct/ProjectProduct.ts` | Type definition consumed by all project UI | Field changes require type updates |
| **Mobile API** | `slab-mobile/` consumers | Fetches project products via API | Response shape changes break mobile parsing |

### `quote_products` — CRITICAL (Highest Blast Radius)

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **GetActualsMetrics** | `/internal/database/queries/actuals.sql:1-213` | `filtered_quote_product_aggregates_cte`: `SUM(quantity)`, `SUM(price_amount)`, `COUNT(*)` grouped by quote_id | Row duplication inflates all metrics |
| **outstanding_backlog_cte** | `/internal/database/queries/actuals.sql:103-116` | Sold volume = SUM of approved quote product quantities | Inflated sold volume, wrong backlog |
| **bid_volume_metrics_cte** | `/internal/database/queries/actuals.sql:53-68` | Monthly bid volume with conditional SUM | Doubled bid volume |
| **project_variance_cte** | `/internal/database/queries/actuals.sql:131-152` | `ABS(quoted - actual) / quoted * 100` for variance detection | Wrong variance %, false at-risk flags |
| **at_risk_projects_cte** | `/internal/database/queries/actuals.sql:153-159` | COUNT of projects exceeding variance thresholds | False positives and negatives |
| **v_quote_products view** | `/internal/database/migrations/auto/v_quote_products.sql` | Complex cost calculations via SQL functions | Cost function inputs change |
| **v_quotes view** | `/internal/database/migrations/auto/v_quotes.sql` | Quote-level revenue aggregation | Row duplication inflates revenue |
| **Plant performance** | `/internal/domain/dbclient/actuals.go:42-170` | `SUM(qp.quantity)` grouped by location_id for quoted volume | Inflated plant-level volume |
| **Monthly breakdown** | `/internal/database/queries/actuals.sql:221-318` | `committed_cte`: SUM(qp.quantity) by location + month | Doubled committed volume |
| **Volume variance alerts** | `/internal/domain/dbclient/actuals_alerts.go:12-162` | Quoted volume vs actual volume comparison | Wrong alert thresholds triggered |
| **Quote approval policies** | `/internal/domain/quote_policy.go` | 30+ threshold evaluations on quote products (margins, quantities, prices) | Duplicate products evaluated, wrong totals |
| **PDF generation** | `/internal/server/pdfgeneratorapi.go` + `/internal/domain/pdf_input.go` | Product line items in quote PDFs | Duplicate line items |
| **Apex export** | `/internal/apex/export.go`, `/internal/apex/orders.go` | Exports quote products to Apex/JWS | Duplicate products in external system |
| **Frontend Quote Drawer** | `/slab-core/src/hooks/useProductSection.ts`, `/slab-core/src/hooks/useQuoteDrawer.ts` | Quote product form management | Array shape changes |
| **Frontend TypeScript types** | `/slab-core/src/types/api/QuoteProduct/QuoteProduct.ts` | Type consumed by all quote UI | Field changes require type updates |

### `projects` — HIGH

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **All project views** | `/internal/database/migrations/auto/v_projects.sql` | Aggregated financial data per project | Override fields change, status field changes |
| **Quotes** | FK `quotes.project_id → projects.id` | Every quote links to a project | Project deletion/archival without quote handling |
| **Forecasts** | FK `forecasts.project_id → projects.id` | Project-level forecasting | Project scope changes affect forecast comparison |
| **Dispatch tickets** | FK `dispatch_tickets.project_id → projects.id` | Actuals tracking | Project linkage changes |
| **Activities** | FK `activities.project_id → projects.id` | Activity logging | Project archival |
| **Project companies** | `project_companies` table | Contractor/customer associations | Company/contact relationship changes |
| **Custom fields** | `project_custom_fields` table | Dynamic field values | Field definition changes |
| **Dashboard queries** | `/internal/domain/dbclient/actuals.go` | All actuals performance summaries | Status field changes, date field changes |

### `quotes` — HIGH

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **Actuals metrics** | `/internal/database/queries/actuals.sql` | Quote-based bid volume, backlog, variance | Status field changes, project linkage |
| **Quote policies** | `/internal/domain/quote_policy.go` | Approval workflows | Status workflow changes |
| **Apex export** | `/internal/apex/export.go` | Full quote export to ERP | Field additions/removals |
| **PDF generation** | `/internal/domain/pdf_input.go` | Quote PDF data assembly | Field changes, product changes |
| **Email/notifications** | `/internal/server/quotes.go` | Quote sent/status change notifications | Status workflow changes |
| **v_quotes view** | `/internal/database/migrations/auto/v_quotes.sql` | Quote revenue, volume aggregation | Product aggregation changes |
| **Quote configs** | `quote_config_products` | Template defaults | Config structure changes |

### `products` — HIGH

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **v_products view** | `/internal/database/migrations/auto/v_products.sql` | Product catalog with computed costs | Cost override fields change |
| **Quote/Project products** | FK from both tables | Product definition for line items | Category changes, measurement unit changes |
| **Cost calculations** | `calculate_other_cost_amount()`, `margin()` SQL functions | Per-unit cost computation | Cost override structure changes |
| **Apex/Connect export** | `/internal/apex/products.go`, `/internal/connect/` | Product sync to external systems | Field additions/removals, category changes |
| **PDF generation** | `/internal/domain/pdf_input.go` | Product details in PDFs | Name/category/unit changes |
| **Mix materials** | Via `mix_id` FK | Ready-mix product composition | Mix relationship changes |
| **Trucking type filtering** | Product category → truck type compatibility | Which truck types available | Category changes |

### `plants` — HIGH

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **Products** | FK `products.plant_id → plants.id` | Product source location | Plant archival, address changes |
| **Forecasts** | FK `forecasts.plant_id → plants.id` | Plant-level budgets/capacity | Plant scope changes |
| **Dispatch tickets** | FK `dispatch_tickets.plant_id → plants.id` | Actuals by plant | Plant linkage changes |
| **Actuals plant performance** | `/internal/domain/dbclient/actuals.go:42-170` | Budget, capacity, quoted, actual by plant | Plant ID changes, location changes |
| **Trucking types** | `plant_trucking_types.plant_id` | Available truck types per plant | Plant archival |
| **Delivery costs** | `delivery_costs` linked via products | Distance/time-based delivery calculations | Address changes affect drive distance |
| **Google Maps queries** | `/internal/server/maps.go` | Distance/drive time from plant to job | Plant address changes |

### `delivery_costs` — MEDIUM-HIGH

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **v_project_products / v_quote_products** | Auto migration views | `total_delivery_cost` calculation | Any input parameter changes |
| **Delivery cost trigger** | `delivery_cost_calculations_tgr` | Auto-computes total on write | Trigger logic changes |
| **product_agg_cte** | `/internal/domain/dbclient/projects.go:170-227` | Includes delivery cost in total_costs_amount | delivery_costs_id linkage changes |
| **PDF product data** | `/internal/domain/pdf_input.go` | Delivery cost line items in PDFs | Cost structure changes |
| **Frontend delivery form** | `/slab-core/src/formik/projectOrQuoteProduct.ts` | DeliveryCost Formik fields | Field additions/removals |

### `dispatch_tickets` — MEDIUM-HIGH (Actuals Foundation)

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **Actuals metrics** | `/internal/database/queries/actuals.sql:86-101` | `SUM(volume)` by date range for actual deliveries | Row duplication, volume field changes |
| **Plant performance** | `/internal/domain/dbclient/actuals.go:42-170` | `SUM(ds.volume)` grouped by plant_id | Plant linkage changes |
| **Project performance** | `/internal/domain/dbclient/actuals.go:171-336` | `SUM(ds.volume)` grouped by project_id | Project linkage changes |
| **Customer performance** | `/internal/domain/dbclient/actuals.go:338-415` | `SUM(volume)`, `AVG(wait_time)`, `AVG(unload_time)` by company | Company linkage changes |
| **Project product breakdown** | `/internal/domain/dbclient/actuals.go:417-501` | `SUM(ds.volume)` by product_id | Product linkage changes |
| **Volume variance alerts** | `/internal/domain/dbclient/actuals_alerts.go` | Actual volume vs quoted volume | Volume field changes |
| **Monthly breakdown** | `/internal/database/queries/actuals.sql:221-318` | Monthly actual volume SUM | Date field changes |
| **Outstanding backlog** | `/internal/database/queries/actuals.sql:103-116` | Shipped volume subtracted from sold volume | Volume aggregation changes |

### `forecasts` — MEDIUM

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **Actuals metrics** | `/internal/database/queries/actuals.sql:70-84` | `forecast_metrics_cte`: SUM by month | Kind field changes, interval changes |
| **Plant performance** | `/internal/domain/dbclient/actuals.go` | Budget and capacity CTEs: `SUM(f.value)` WHERE kind='budget'/'capacity' | Kind enum changes |
| **Project performance** | `/internal/domain/dbclient/actuals.go` | Planned volume: `SUM(f.value) * p.confidence` | Confidence calculation changes |
| **Monthly breakdown** | `/internal/database/queries/actuals.sql:221-318` | Budget by month by plant | Plant linkage changes |
| **Frontend forecasts page** | `/slab-web/src/pages/Forecasts/` | Forecast management UI | Type/field changes |

### `quote_statuses` — MEDIUM (Controls Aggregation Filtering)

| Downstream Consumer | File | What It Does | Breaks When |
|---------------------|------|--------------|-------------|
| **All actuals queries** | `/internal/database/queries/actuals.sql` | Filters on `is_sent`, `is_approved_to_send`, `is_archived`, `is_rejected`, `is_buyer_rejected` | Flag semantics change |
| **Quote approval workflow** | `/internal/server/quotes.go` | Status transition rules | New statuses added |
| **Quoted volume CTEs** | `/internal/domain/dbclient/actuals.go` | `WHERE qs.is_sent = true` for committed volume | is_sent meaning changes |
| **Outstanding backlog** | `/internal/database/queries/actuals.sql:103-116` | Filters to approved/sent quotes only | Flag changes |

---

## 2. Critical Financial Aggregation Queries (PROTECT AT ALL COSTS)

These queries are the financial backbone of the system. Any change that affects the data they consume MUST be analyzed against these specific locations.

### A. `product_agg_cte` — Project Revenue, Costs, Volume

**File:** `/internal/domain/dbclient/projects.go:170-227`

```sql
SUM(price_amount * quantity) AS revenue_amount        -- Project revenue
SUM(cost * quantity) AS total_costs_amount             -- Project total costs
SUM(products.quantity * quantity) AS estimated_volume   -- Project volume
-- Plus: ready_mix_quantity, asphalt_quantity, aggregate_quantity (with unit conversions)
```

**Assumption:** One `project_products` row = one product in the project. If the same product appears multiple times (e.g., different trucking types), these SUMs multiply.

**When to check this:** ANY change to `project_products` table structure, any change to how products are added to projects, any change to quantity/price fields.

### B. `GetActualsMetrics` — Dashboard Financial Metrics

**File:** `/internal/database/queries/actuals.sql:1-213`

Contains 8+ CTEs that chain together:
- `filtered_quote_product_aggregates_cte` (line 43-51): `SUM(quantity)`, `SUM(price_amount)`, `COUNT(*)` — **breaks if quote_products rows are duplicated**
- `bid_volume_metrics_cte` (line 53-68): Monthly bid volume — **breaks if quote quantities inflate**
- `outstanding_backlog_cte` (line 103-116): Sold minus shipped — **breaks if sold volume inflates**
- `project_variance_cte` (line 131-152): Quoted vs actual — **breaks if quoted volume is wrong**
- `at_risk_projects_cte` (line 153-159): Risk detection — **produces false alerts if variance is wrong**

**When to check this:** ANY change to `quote_products`, `quotes`, `quote_statuses`, `dispatch_tickets`, `forecasts`.

### C. Plant/Project/Customer Performance Summaries

**File:** `/internal/domain/dbclient/actuals.go`

- Plant performance (lines 42-170): Budget, capacity, quoted volume, actual volume by plant
- Project performance (lines 171-336): Quoted volume, actual volume, planned volume with confidence weighting
- Customer performance (lines 338-415): Volume, wait time, unload time by customer
- Product breakdown (lines 417-501): Per-product volume as percentage of project total

**When to check this:** ANY change to `dispatch_tickets`, `forecasts`, `quote_products`, `projects`.

### D. Monthly Breakdown

**File:** `/internal/database/queries/actuals.sql:221-318`

- `committed_cte`: `SUM(qp.quantity)` by location + month
- `actual_volume_cte`: `SUM(ds.volume)` by project + month
- Backlog: `budget - committed - actual`

**When to check this:** ANY change to budget, committed volume, or actual volume data sources.

### E. Volume Variance Alerts

**File:** `/internal/domain/dbclient/actuals_alerts.go:12-162`

Two alert types:
1. Volume variance: `ABS(quoted - actual) / quoted * 100` with severity thresholds (>50% HIGH, >30% MEDIUM, >15% LOW)
2. Project delays: Date-based overdue detection

**When to check this:** ANY change to `dispatch_tickets`, `quote_products`, project dates.

### F. Views That Aggregate Data

**Files in `/internal/database/migrations/auto/`:**
- `v_projects.sql` — Aggregates project_products into revenue, costs, volumes
- `v_quotes.sql` — Aggregates quote_products into quote revenue, volumes
- `v_project_products.sql` — Computes per-product costs via SQL functions
- `v_quote_products.sql` — Computes per-product costs via SQL functions

**When to check these:** ANY change to the base tables they query, any change to the SQL functions they call (`calculate_other_cost_amount`, `calculate_with_delivery_subtotal_price`, `calculate_with_delivery_total_price`, `margin`, `convert_units`).

---

## 3. Critical Path Registry

These are the data flow chains where a change at any node can silently corrupt downstream systems. When modifying any node, trace the FULL path.

### Path 1: Product Pricing → Financial Reporting
```
Product.list_price
  → QuoteProduct.price / ProjectProduct.price
    → product_agg_cte: SUM(price * quantity) = revenue
      → v_projects.revenue_amount
        → Dashboard project cards
        → Forecast comparison (planned revenue vs actual)
        → Actuals metrics (outstanding backlog value)
```
**If price changes:** Revenue calculations cascade through every aggregation.

### Path 2: Product Quantity → Volume Tracking → Forecasting
```
QuoteProduct.quantity / ProjectProduct.quantity
  → product_agg_cte: SUM(quantity) = estimated_volume
    → v_projects.estimated_volume
      → bid_volume_metrics_cte (actuals.sql)
      → outstanding_backlog_cte (actuals.sql)
      → project_variance_cte (actuals.sql)
        → at_risk_projects_cte → Alerts
          → ActualsAlerts → Dashboard variance warnings
  → committed_cte (actuals.sql) → Monthly breakdown
  → Forecast comparison: planned vs actual variance
```
**If quantity changes or rows multiply:** Every volume metric in the system is wrong.

### Path 3: Product Costs → Margin Calculations → Approval Workflows
```
Material.in_product_cost + CostRule.apply()
  → Product.material_cost + Product.other_cost
    → QuoteProduct: material_cost, other_cost (computed via SQL functions)
      → v_quote_products: with_delivery_subtotal_price, with_delivery_total_price
        → Quote.revenue (sum of product totals)
          → QuotePolicy evaluation (30+ threshold checks)
            → Policy violations → Approval workflow
              → Quote status transitions
                → Apex export (only sent/approved quotes)
                  → External ERP system
      → product_agg_cte: SUM(cost * quantity) = total_costs
        → v_projects.total_costs
          → Project margin calculations
            → Dashboard margin displays
```
**If cost inputs change:** Margins change → policy violations change → approval workflow behaves differently → wrong quotes may get auto-approved or blocked.

### Path 4: Dispatch Data → Actuals → Variance Detection
```
External dispatch system (Sysdyne/Apex/BCMI)
  → dispatch_tickets: volume, plant_id, project_id, product_id, delivered_date
    → actual_metrics_cte: SUM(volume) by date range
      → ActualsMetrics.actualDeliveries
    → outstanding_backlog_cte: shipped volume
      → Backlog = sold - shipped
    → project_variance_cte: actual vs quoted
      → at_risk_projects_cte → ActualsAlerts
    → Plant performance: SUM(volume) by plant
    → Customer performance: SUM(volume), AVG(wait_time) by company
    → Product breakdown: SUM(volume) by product as % of project total
    → Monthly breakdown: SUM(volume) by month
```
**If dispatch ticket structure changes:** Every actuals metric is affected.

### Path 5: Quote → Project Conversion → Downstream
```
Quote (with products, company, contacts)
  → "Convert to Project" flow
    → Project created with quote's products, companies
      → project_products created from quote_products
        → All Path 1 and Path 2 cascades apply
      → Forecasts initialized
      → Apex notified
```
**If quote structure changes:** Conversion logic must handle new fields/relationships.

### Path 6: Plant Configuration → Product Defaults → Pricing
```
Plant
  → ReadyMixConstants (operating_cost, sga_cost, logistics_cost, margins)
    → Product.other_cost calculation (when no override)
      → All Path 3 cascades apply
  → PlantTruckingTypes
    → QuoteProduct/ProjectProduct.trucking_type_id
      → Haul rate defaults, minimum haul charge defaults
        → Delivery cost calculations
          → All Path 3 cascades apply
  → DeliveryCost (plant-level defaults)
    → Per-product delivery cost (when no product-level override)
      → All Path 3 cascades apply
  → CostRule (material markup)
    → Material.in_product_cost
      → All Path 3 cascades apply
```
**If plant configuration changes:** Cascades through product pricing, margins, delivery costs, and all downstream financial metrics.

---

## 4. Mandatory Blast Radius Analysis Protocol

When ANY change is proposed, Claude MUST perform this analysis BEFORE writing code.

### Step 1: Identify Affected Entities
- What database tables are directly modified?
- What domain models change?
- What API endpoints are affected?

### Step 2: Check the Entity Dependency Map (Section 1)
- For EACH affected entity, look up its downstream consumers in the map above.
- List every downstream consumer that could be affected.

### Step 3: Search for Aggregation Queries
Run these searches to find any aggregation that consumes the affected data:
```bash
# Search for SUM/COUNT/AVG on the affected table
grep -rn "SUM\|COUNT\|AVG\|GROUP BY" internal/database/queries/ internal/domain/dbclient/ --include="*.go" --include="*.sql" | grep -i "<table_name>"

# Search for views that reference the affected table
grep -rn "<table_name>" internal/database/migrations/auto/v_*.sql

# Search for CTEs that reference the affected table
grep -rn "FROM.*<table_name>\|JOIN.*<table_name>" internal/database/queries/ internal/domain/dbclient/ --include="*.go" --include="*.sql"
```

### Step 4: Check Critical Financial Queries (Section 2)
- Does this change affect ANY input to the queries listed in Section 2?
- If YES: explicitly document HOW the aggregation results will change.

### Step 5: Trace Critical Paths (Section 3)
- Is the affected entity part of ANY critical path?
- If YES: trace the FULL path to identify all downstream effects.

### Step 6: Check Cross-System Impact (Section 5 checklist)
- Run through the full cross-system checklist below.

### Step 7: Present Blast Radius
Before writing any code, present the analysis:
```
## Blast Radius Analysis

### Direct Changes
- [Table/model/endpoint being modified]

### Downstream Impact
- [List every downstream consumer affected]
- [For each: what specifically changes and whether it's safe]

### Financial Query Impact
- [product_agg_cte: SAFE/AFFECTED — reason]
- [GetActualsMetrics: SAFE/AFFECTED — reason]
- [Performance summaries: SAFE/AFFECTED — reason]
- [Alerts: SAFE/AFFECTED — reason]

### Cross-System Impact
- [For each system in checklist: SAFE/AFFECTED — reason]

### Risk Level: [LOW/MEDIUM/HIGH/CRITICAL]
### Recommendation: [Proceed / Needs mitigation / Needs design review]
```

---

## 5. Cross-System Verification Checklist

For ANY change, check impact on ALL of these systems. Mark each as SAFE or AFFECTED with explanation.

| # | System | What to Check | Key Files |
|---|--------|---------------|-----------|
| 1 | **Financial reporting** | Revenue, costs, margins, volume SUMs. Check `product_agg_cte`, `v_projects`, `v_quotes` | `projects.go:170-227`, `actuals.sql`, `v_projects.sql`, `v_quotes.sql` |
| 2 | **Forecasting** | Planned vs actual comparisons, variance calculations, budget/capacity | `actuals.sql:70-84`, `actuals.go` budget/capacity CTEs, `forecasts.go` |
| 3 | **Actuals/Backlog** | Bid volume, outstanding backlog, at-risk detection, monthly breakdown | `actuals.sql` (all CTEs), `actuals_alerts.go` |
| 4 | **Mobile app** | API response shapes, feature flag behavior, push notifications | `slab-mobile/` consumers, `/internal/server/` handlers with mobile notes |
| 5 | **PDF generation** | Quote PDF line items, product details, computed fields | `/internal/domain/pdf_input.go`, `/internal/server/pdfgeneratorapi.go` |
| 6 | **Apex integration** | Quote/product/material/company export | `/internal/apex/export.go`, `/internal/apex/products.go`, `/internal/apex/companies.go`, `/internal/apex/orders.go` |
| 7 | **Series integration** | Financial data export | `/internal/series/` |
| 8 | **Sysdyne integration** | Dispatch ticket import | `/internal/sysdyne/` |
| 9 | **Connect integration** | Product/material/mix export | `/internal/connect/` |
| 10 | **Email/notifications** | Quote sent notifications, status change alerts, push notifications | `/internal/server/quotes.go`, notification system |
| 11 | **Search/filtering** | List endpoints with dynamic query builders, typeahead endpoints | `/internal/domain/dbclient/` — `buildXxxQueryBuilder()` functions |
| 12 | **Permissions/visibility** | Role-based access, scope checks, domain type permissions | `/internal/roles/middleware.go`, `/internal/scopes/middleware.go` |
| 13 | **Quote approval workflow** | Policy threshold evaluations (30+ types), violation state management | `/internal/domain/quote_policy.go` (800+ LOC of margin calculations) |
| 14 | **Data import/export** | CSV import, Apex/Series/Sysdyne/Connect sync | Import functions in domain models implementing `Importable` interface |
| 15 | **Audit trail** | Trigger-based audit logging | `audit.log` table, database triggers |
| 16 | **Views and computed columns** | SQL views that aggregate or compute from base tables | `/internal/database/migrations/auto/v_*.sql` |
| 17 | **SQL functions** | Cost calculation, margin, unit conversion, delivery cost functions | `/internal/database/migrations/auto/calculate_*.sql`, `margin.sql`, `convert_units.sql` |
| 18 | **Formik schemas / validation** | Frontend form state and Yup validation rules | `/slab-core/src/formik/` — especially `projectOrQuoteProduct.ts`, `project.ts`, `quote.ts` |
| 19 | **Frontend shared hooks** | Hooks used across multiple pages | `/slab-core/src/hooks/useProductSection.ts` (42KB, shared between project and quote drawers) |
| 20 | **Dashboard / Metabase** | Embedded dashboards that query the database | `/internal/domain/dashboard.go`, Metabase integration |

<!-- Extracted from root CLAUDE.md on 2026-01-30: Sections 1-5 moved to on-demand reference doc -->
