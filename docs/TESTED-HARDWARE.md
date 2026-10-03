# Hardware matrix

The committed Kanshi profile is intentionally hardware-neutral so the
repository stays free of asset identifiers. This file records which machines the
configuration has actually been verified on.

Do not commit serials, asset tags, or internal hostnames. Record the fields
below only.

## Verification checklist

A machine counts as verified when all of the following pass on a freshly
applied deployment:

- Boots to the Sway session with the intended resolution and scale, applied by
  Kanshi.
- Exactly one Waybar instance is running.
- Suspend and resume both work, including wake to a locked screen.
- Volume, mute, and brightness keys change state once per press.
- Displays power off after the idle timeout and wake on input.
- The GPU driver is the expected one with no fallback to software rendering.
- Audio output and input both work over PipeWire.
- `workstation-bootstrap verify` passes.

Record the output of:

```bash
swaymsg -t get_outputs | jq -r '.[] | "\(.make) \(.model)"' | sort -u
lspci -nnk | grep -A3 -E 'VGA|3D|Display'
bootctl status | head -5
```

## Verified machines

| Machine | CPU/GPU | Session | Verified on | Notes |
| --- | --- | --- | --- | --- |
| _(unpopulated)_ | | | | |

An empty table means the repository has not been verified on any hardware yet.
Treat first-use machines as untested and keep a terminal reachable.

## GPUs without hardware acceleration

Sway requires working DRM/KMS. If a machine renders through llvmpipe or falls
back to software, check whether the required driver is present on the host:

```bash
sudo rpm-ostree install mesa-vaapi-intel
```

Common causes of software rendering are a missing or mismatched kernel module
and firmware that is too old to expose the display engine. Check
`journalctl -b -k | grep -i -E 'drm|amdgpu|i915|nouveau'` before adding packages.

## Multi-GPU and docking

When docking changes connector numbering, prefer make/model/serial criteria over
connector names in Kanshi, because connector names are not stable across boots
with some dock firmware. See [Customization](CUSTOMIZATION.md).

## Adding an entry

Keep entries minimal. A GPU model and the verification date are enough to be
useful; serials and internal identifiers are not needed and should not be
committed.
