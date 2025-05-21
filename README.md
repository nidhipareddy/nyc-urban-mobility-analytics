# NYC Urban Mobility Analytics

Final project for Data Engineering I @ UChicago Master's in Applied Data Science.  
This project explores NYC taxi and rideshare data using dimensional modeling, SQL, and Tableau to uncover urban mobility patterns and inform equitable transit planning.

## 📊 Project Overview

We engineered a relational database schema, ingested ride data using DDL and DML SQL scripts, and wrote analytical queries to identify:
- Peak demand zones and time periods
- Accessibility gaps across boroughs
- Rider behavior during rush hours
- Traffic patterns in relation to population density

## 🛠️ Technologies Used

- **SQL (MySQL)**: For schema creation, data population, and analytical queries
- **Google Cloud Platform (GCP)**: Hosted MySQL database
- **Tableau**: For interactive dashboards and geospatial visualizations
- **Python (optional extension)**: For data cleaning and preprocessing (not included here)

## 📁 Project Structure

```bash
nyc-urban-mobility-analytics/
│
├── schema/
│   ├── Group3_DDL.sql         # SQL for table creation
│   └── Group3_DML.sql         # SQL for data population
│
├── queries/
│   └── Group3_Queries_for_analysis.sql  # Analytical queries
│
├── docs/
│   ├── Group 3- DEP Final project.pdf    # Final report
│   └── Group3_finalproject_dataengg.twb  # Tableau workbook
