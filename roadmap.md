# Seerr iOS Roadmap

Statuses: ☐ Not started · ⏳ In progress · ✅ Done

## Near term
- ☐ Request options: 4K toggle, quality/profile/root/tags, per-season selection for TV before submitting. *(4K toggle + per-season selection done; profiles/root/tags remain)*
- ☐ Detail polish: cast, runtime/episode counts, trailers, watch providers, Overseerr status (SD/4K), deep link to Overseerr. *(cast/providers/trailer/runtime/season counts/deep link done)*
- ☐ Requests management: cancel/delete or retry; approval/decline for authorized users; show request history/activity.
- ☐ Discover filters: genre/year/sort, trending by day/week, upcoming rails, keyword/people search tabs. *(basic genre/year/sort + trending period added; upcoming & keyword/people tabs remain)*
- ☐ Related content: recommendations/similar titles and collections/franchises on detail screens; quick request actions.
- ☐ Offline/empty: cache last results for requests/discover; clearer error banners and retry actions.
- ☐ Notifications UX: local or in-app banners when a request completes or fails (polling or webhooks).
- ⏳ Settings/profiles: switch Overseerr profiles, show current user/permissions; advanced fields behind an “Advanced” section. *(profile fetch + advanced section + reset done; profile switching via API key still manual)*
- ☐ Theming polish: configurable accent color, dark mode tuning, larger artwork layouts, haptics on key actions.
- ☐ Testing/CI: unit tests for API/model decoding; snapshot/UI tests for discover/detail/request flows; CI job running `make test`.

## Later
- ☐ Caching layer for posters/thumbnails.
- ☐ Download/offline queue for detail metadata.
- ☐ Home widgets or Live Activities once request status events are available.
