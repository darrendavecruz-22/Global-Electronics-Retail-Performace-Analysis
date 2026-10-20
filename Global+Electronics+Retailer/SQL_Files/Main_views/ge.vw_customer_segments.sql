/* =============================================================================
   View: ge.vw_customer_segments

   Purpose: Final customer table for Power BI. Brings together customer
   demographics, lifetime totals, and RFM segments in one view.

   Notes: Joins the customer summary view to the RFM view on CustomerKey
   so that each customer has their profile, order totals, RFM
   scores, and segment in a single row.
   ============================================================================= */

CREATE OR ALTER VIEW ge.vw_customer_segments AS
SELECT
    s.CustomerKey, s.Name, s.Gender, s.Country, s.Continent,
    s.Age, s.Age_bracket, s.Age_bracket_order,
    s.First_Order_Date, s.Last_Order_Date,
    s.Orders, s.Units_sold, s.Revenue, s.Profit,
    r.Recency_Days, r.R_score, r.F_score, r.M_score, r.RFM_Segment,
    CASE r.RFM_Segment
        WHEN 'Champions' THEN 1 WHEN 'Loyal' THEN 2
        WHEN 'Recent Customers' THEN 3 WHEN 'Needs Attention' THEN 4
        WHEN 'At Risk' THEN 5 ELSE 6
    END AS Segment_order   -- for sorting charts in Power BI
FROM ge.vw_customer_summary AS s
JOIN ge.vw_customer_rfm AS r ON r.CustomerKey = s.CustomerKey;
GO