# ALISHAMS Mobile App Plan

## Visual direction
Premium Persian RTL digital-studio app inspired by the approved reference: near-black navy (#070B18), glass-like navy surfaces (#121A2B), electric violet (#8B5CF6), cyan (#22D3EE), Vazirmatn typography, subtle glow, generous spacing, refined rounded cards, and a dark bottom navigation.

## Completed
- Splash and mock authentication screens.
- Home dashboard with premium violet/cyan hero and Plus+ visual banner.
- Services screen.
- Orders screen with honest backend-pending state.
- Account screen with profile summary, Plus+ and customer-club placeholders, settings/support entries, and mock sign-out.

## Important integration boundary
Authentication is currently mock-only. Account, orders, Plus+, customer-club points, leagues, rewards, and notifications are not connected to the live ALISHAMS website or backend. No real account or transaction data is fabricated. Verify the existing backend API, authentication model, and database schema before integration; use least-privilege authenticated endpoints and never expose service-role credentials.

## Scope
The live alishams.ir website is not modified by this app project.
