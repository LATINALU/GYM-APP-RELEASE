/// Which published app/binary this process is running as (client, staff,
/// owner, or the private admin tool) — set by the `lib/main_<flavor>.dart`
/// entry point that launched it and threaded through bootstrap/DI/router.
enum AppFlavor { client, staff, owner, admin }
