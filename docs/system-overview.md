# GramTransit System Overview

GramTransit is built on several core principles tailored for rural, low-connectivity transit.

## Principles

- **Schedule-first**: Scheduled information remains useful when backend/network/GPS/realtime are unavailable. Realtime tracking is considered a later enhancement, not a baseline requirement.
- **Guest-first**: Public transit information should be accessible without mandatory login. Authentication is only required when personal/synced functionality needs it.
- **Accessible and multilingual-ready**: English first, with planned support for Kannada and Malayalam. UI is built using Material 3 with large touch targets, readable typography, and WCAG-conscious contrast.
- **Lightweight**: Targeted at weak networks and low-end Android devices, minimizing unnecessary dependencies and abstractions.

## Planned System Boundaries

- **Flutter mobile apps**: Passenger and Driver apps for end-users and operators.
- **Next.js admin**: Web interface for managing transit schedules and routes (Planned).
- **Java Spring Boot backend**: Core API and business logic (Planned).
- **PostgreSQL system of record**: Persistent relational database for schedules, stops, and routes (Planned).
- **Redis ephemeral realtime/cache state**: High-speed cache for live locations and temporary state (Planned).

*Note: Currently, only the Passenger Flutter app is in active development.*
