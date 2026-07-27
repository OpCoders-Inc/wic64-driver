# WiC64 Network Hardware Driver for C64 OS

## Project Overview

NHD (Network Hardware Driver) for the WiC64 cartridge, using the User Port parallel interface (ZiModem-like protocol). Enables C64 OS network.lib/cnp.lib to access TCP/IP via WiC64.

## Active Development: `src1/`

The current working iteration. Produces `nhd.upwc.64` loaded into C64 OS as a network driver.

## Build System

- **Assembler:** Turbo Macro Pro (TMP)
- **Load address:** `*=$b300` (set in `build.asm`)
- **Includes:** C64 OS module headers via `os/h/` and `os/s/`
- **Bundle:** `bundle.ini` → builds `nhd.upwc.64` → `wic64.d64`
- **Output:** `src1/out/nhd.upwc.64`
- **Build:**
  ```
  ; in IceBrolt or with cc64
  bundle.ini → build.asm → wic64.d64
  ```

## Project Layout

```
wic64/
├── AGENTS.md
├── TECHNICAL.md               # Full technical reference (protocols, architecture, known bugs)
├── bundle.ini
├── src1/                      # CURRENT - main development (clean baseline)
│   ├── build.asm              # Entry point, *= $b300, includes all .asm files
│   ├── wic64.h                # WiC64 commands, CIA2 regs, macros (WC_ prefix)
│   ├── main.asm               # Jump table, buffer ops (push/pop cmd/rcv/snd), delay, handlers
│   ├── inc.asm                # C64 OS module includes (app, network, nhd, pointer, memory, screen, service)
│   ├── vars.asm               # Zero-page vars (sptr=$61, ptr=$63)
│   ├── data.asm               # Buffers (snd/rcv/cmd), payload storage
│   ├── jlink.asm              # jlink: init external calls
│   ├── junlink.asm            # junlink: stub (RTS)
│   ├── jsethand.asm           # jsethand: store carrier/command mode handlers
│   ├── jpollget.asm           # jpollget: poll cmd_buff → flush snd → WiC64 avail/read
│   ├── jssidstat.asm          # jssidstat: join/read SSID (join not implemented, fakes ack)
│   ├── jdataget.asm           # jdataget: read byte from cmd_buff or WiC64
│   ├── jdataput.asm           # jdataput: push byte to snd_buff
│   ├── jsetrate.asm           # jsetrate: stub (RTS)
│   ├── jopensock.asm          # jopensock: parse host:port → TCP_OPEN
│   ├── wic64.asm              # Low-level WiC64 protocol & variable storage
│   └── sys.asm                # External syscalls (pgalloc, pgfree, pet2asc, quitapp)
├── src2/                      # 2nd iteration (exploration)
├── src3/                      # 3rd iteration (previous dev work, driver3)
├── src4/                      # 4th iteration (experiment)
├── os/h/                      # C64 OS header includes
├── os/s/                      # C64 OS system includes
├── apps/                      # Test applications
├── tests/                     # Test programs
├── out/                       # Build output
└── wic64.d64                  # D64 disk image
```

## C64 OS Networking Stack

```
Application → network.lib → cnp.lib → nhd.* driver (this one) → WiC64 hardware
```

The driver is called via a jump table at its load address:

| Offset | Entry     | Description                     |
|--------|-----------|---------------------------------|
| `+$00` | `jlink`   | Load/initialize driver          |
| `+$03` | `junlink` | Unload driver                   |
| `+$06` | `jsethand`| Set carrier/command handlers    |
| `+$09` | `jpollget`| Poll for incoming data          |
| `+$0c` | `jdataget`| Get byte from buffer            |
| `+$0f` | `jdataput`| Put byte into send buffer       |
| `+$12` | `jsetrate`| Set baud rate (stub)            |
| `+$15` | `jssidstat`| Join or read SSID               |
| `+$18` | `jopensock`| Open or close TCP socket        |
| `+$1b` | `nhdpause` | Pause IRQ handling (stub)       |
| `+$1e` | `nhdresume`| Resume IRQ handling (stub)      |

## Driver Architecture

The driver uses a command buffer pattern to return ack/status bytes to network.lib:

1. **ssidstat / opensock** send WiC64 commands, then push ack bytes (e.g., `"0"` `$0d`) into `d_cmd_buff`
2. **jpollget** checks `d_cmd_buff` first — if data exists, calls carrier mode handler (carrier=online)
3. **jdataget** pulls from `d_cmd_buff` or reads raw from WiC64 via `wic64_read_byte`
4. **jdataput** accumulates bytes in `d_snd_buff`; `jpollget` flushes via `flush_snd_buff` when buffer has data
5. **jpollget** also polls WiC64 with `WC_TCP_AVAIL` / `WC_TCP_READ` to check for incoming data
6. `d_payload_sz` tracks pending WiC64 payload bytes; `jdataget` reads them one at a time

## WiC64 Hardware Protocol (User Port Parallel)

- **PA2** (`$dd00` bit 2): direction control — high=send, low=recv
- **PB** (`$dd01`): 8-bit data
- **FLAG2** (`$dd0d` bit 4): handshake
- Command format: `"r"` + command byte + payload_len_lo + payload_len_hi + [payload...]
- Response: dummy byte + status + payload_len_lo + payload_len_hi + [payload...]

## Key Constants (wic64.h / WC_*)

- `WC_TCP_OPEN=$21`, `WC_TCP_AVAIL=$30`, `WC_TCP_READ=$22`, `WC_TCP_WRITE=$23`, `WC_TCP_CLOSE=$2e`
- `WC_CONN_SSID=$02`, `WC_GET_SSID=$10`, `WC_IS_CONNECT=$2c`, `WC_IS_CONFIG=$2f`
- `WC_GET_VER_STR=$00`, `WC_ECHO=$fe`

## Buffers & Variables (data.asm)

| Label       | Size | Purpose                    |
|-------------|------|----------------------------|
| `d_state`   | 16   | Driver state (offline=#$ff, online=#$00, wifi, opened, closed) |
| `d_snd_buff`| 64   | Outgoing data to WiC64     |
| `d_rcv_buff`| 64   | Incoming data (currently unused) |
| `d_cmd_buff`| 16   | Command ack bytes for CNP  |
| `d_payload_sz` | 2  | Pending WiC64 payload size |
| `d_payload_sts` | 1  | Pending WiC64 payload status |
| `w_payload` | 64   | Working buffer (host:port) |

## Known Problems & TODOs

### Protocol Bugs (src1/wic64.asm vs Official WiC64 Library v2.0.0+)

- **Response header reads dummy byte:** Official protocol has NO dummy byte before status (header = status + size_lo + size_hi = 3 bytes). Our code reads dummy + status + size_lo + size_hi (4 bytes). Causes desync.
- **Receive mode misses handshake:** `wic64_do_recv_mode` sets DDRB=0 and PA2=low but never waits for FLAG2 or reads $dd01 as acknowledge. The first `wic64_read_byte` after mode switch eats the direction-change handshake instead of getting real data.
- **Payload counted by NUL terminator:** Official library uses explicit 2-byte size in the header. Our `wic64_do_send_command_with_payload` counts bytes until NUL, which breaks binary data.
- **No timeout handling:** `wic64_read_byte` and `wic64_write_byte` spin forever on FLAG2 with no timeout. Official library has a configurable 3-level cascading timeout (~1-255 seconds).
- **No IRQ management:** Official library saves/restores IRQ state and disables IRQs during transfers for speed (~42KB/s).
- **No error status parsing:** Official library returns status codes 0-5 in every response header. Our code ignores them.

### Missing Features

- **WiFi join:** `jssidstat` does not actually send `WC_CONN_SSID` to WiC64; only fakes ack bytes
- **Online detection:** `jpollget` checks `$0245` (netstat) for `#$3f` — fragile, needs proper `WC_IS_CONNECT` query
- **No WiC64 detection:** `jlink` should verify hardware presence (e.g., `WC_ECHO` or `WC_GET_VER_STR`)
- **Send buffer:** `flush_snd_buff` appends NUL and sends one `WC_TCP_WRITE` per flush; should buffer more before sending
- **rcv_buff:** allocated but unused; current code reads directly from WiC64 in jdataget
- **Buffer sizes:** fixed with `.repeat`; should use `pgalloc` for proper page-sized buffers
- **IRQ handling:** `nhdpause`/`nhdresum` are stubs; no actual CIA2 FLAG2 IRQ is configured

## Coding Conventions

- Turbo Macro Pro syntax: `.block`/`.bend`, `.ifdef`, `.var`, `.repeat`
- C64 OS macros: `#inc_s`, `#inc_h`, `#syscall`, `#ldxy`, `#stxy`, `#w_rcv_dat`, `!sptr`, `!ptr`
- Debug: `debug = 1` enables border color changes + `.text` markers
- Comments: `;` prefix, `;---------------------------------------` section separators
- Self-modifying code patterns (e.g., `mode_carrier+1` / `mode_command+1` for handler vectors)
- Entry points in `j*.asm` files are thin wrappers; core logic in `main.asm` and `wic64.asm`

## Testing

Tests are in `tests/` (`wc*.asm`) and `apps/`. Run via:
- IceBrolt emulator with VICE
- `driver_template.asm` documents the expected NHD API contract
