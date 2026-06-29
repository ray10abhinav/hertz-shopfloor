# Hertz Perfumes — Shopfloor Visibility System

A real-time production tracking system built for Hertz Perfumes & Cosmetics Pvt. Ltd.
Replaces paper-based daily production reports with a live web dashboard.

## What it does
- Production planner uploads daily Excel plan → saved to PostgreSQL
- Line supervisors enter actuals against planned SKUs from any device
- Dashboard shows live plan vs actual with delta and efficiency % per line
- Full audit trail — reasons for delta, batch numbers, time periods

## Tech stack
- Frontend: Vanilla HTML/CSS/JS (single file, no framework)
- Backend: Python FastAPI
- Database: PostgreSQL with a live report VIEW (plan JOIN actuals)

## Live demo
[Open the app](https://hertz-shopfloor-production.up.railway.app)

## Built by
Abhinav — IIM Ahmedabad MBA 2025  
Senior Engagement Manager, Practus Advisors  
Operations transformation engagement at Hertz Perfumes
