# Database Field Specification Rules

When writing database field specifications for new features or tables:

1. **ALWAYS check existing schema first** before proposing new field types:
   - Search migrations in `/internal/database/migrations/` for similar field names
   - Check Go domain models in `/internal/domain/` for type definitions
   - Look at TypeScript types in `/slab-core/src/types/api/` for frontend representations

2. **Match existing field types exactly** when a field concept already exists:
   - If `minimum_haul_charge` is `BIGINT` in `quote_products`, use `BIGINT` everywhere
   - Currency amounts use the `public.currency` composite type
   - Costs with units use the `public.cost` composite type
   - Tax rates use `NUMERIC(3,2)`

3. **Common field type conventions in this codebase**:
   | Field Type | Database Type | Go Type | Notes |
   |------------|---------------|---------|-------|
   | IDs | `UUID` | `uuid.UUID` | Always use gen_random_uuid() default |
   | Money amounts | `public.currency` | `currency.Currency` | Composite: (number, currency_code) |
   | Integer amounts (cents) | `BIGINT` | `null.Int` | For minimum charges, quantities |
   | Percentages/rates | `NUMERIC(3,2)` | `decimal.NullableDecimal` | For tax rates |
   | Timestamps | `TIMESTAMP WITHOUT TIME ZONE` | `time.Time` | Use NOW() default |
   | Soft deletes | `archived_at TIMESTAMP` | `date.NullableDate` | NULL = active |
   | Names/text | `TEXT` | `string` or `null.String` | |
   | Booleans | `BOOLEAN` | `bool` | |

4. **Before finalizing any DB spec**, run these searches:
   ```bash
   # Search for existing field names in migrations
   grep -r "field_name" internal/database/migrations/

   # Search in Go domain models
   grep -r "FieldName" internal/domain/
   ```

5. **When in doubt**, reference these key tables for hauling/trucking patterns:
   - `quote_products` - has `minimum_haul_charge`, `haul_rate`, `haul_cost`, `trucking_type_id`
   - `plant_trucking_types` - the trucking type reference table
   - `project_products` - similar hauling fields for projects

<!-- Extracted from root CLAUDE.md on 2026-01-30: Database Field Specification Rules moved to on-demand reference doc -->
