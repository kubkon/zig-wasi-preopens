# zig-wasi-preopens

A simple project demonstrating the proposed mechanism for fetching and managing WASI preopens
from the runtime in Zig's `libstd`, namely the [`PreopenList`]. The PR in question is [#5231].

[`PreopenList`]: https://github.com/kubkon/zig/blob/wasi-preopens/lib/std/fs/wasi.zig#L47
[#5231]: https://github.com/ziglang/zig/pull/5231

## Building

Note that until the PR is merged into upstream, you'll need to build `zig` using my fork
which can be found [here](https://github.com/kubkon/zig/tree/wasi-preopens).

From the project's root, invoke:

```
zig build.zig
```

This will place the executable WASI module in `zig-cache/bin/wasi_preopens.wasm`.

## Running

To run the generated WASI module, you'll need a WASI-compatible runtime. However, I strongly
recommend you use [`wasmtime`] which allows you to easily trace the syscalls that our Zig-compiled
Wasm calls.

[`wasmtime`]: https://github.com/bytecodealliance/wasmtime

Note that our module wants to create a file in `.`, hence, in WASI terms, we need to pass in
appropriate capabilities to the runtime. We will run the module in two ways here however: first
without, and the with the required capabilities.

### Without required capabilites

Invoking

```
RUST_LOG=wasi_common=trace wasmtime zig-cache/bin/wasi_preopens.wasm
```

will output "capabilities insufficient" error in our binary since we haven't given the module
access (i.e., capability) to `.`. Note that in the invocation we've added `RUST_LOG=wasi_common=trace`
which will enable syscall tracing in `wasmtime` so that we can see exactly what is going on.
And this is the output you should observe:

```
 DEBUG wasi_common::ctx > WasiCtx inserting entry PendingEntry::Thunk(0x7ffee44a04c8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 0 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 0 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(0)
 DEBUG wasi_common::ctx                 > WasiCtx inserting entry PendingEntry::Thunk(0x7ffee44a04c8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 1 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 1 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(1)
 DEBUG wasi_common::ctx                 > WasiCtx inserting entry PendingEntry::Thunk(0x7ffee44a04c8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 2 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 2 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(2)
 DEBUG wasi_common::old::snapshot_0::ctx > WasiCtx inserting (0, Some(PendingEntry::Thunk(0x7ffee44a5db0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 0 is a char device
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx inserting (1, Some(PendingEntry::Thunk(0x7ffee44a5dc0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 1 is a char device
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx inserting (2, Some(PendingEntry::Thunk(0x7ffee44a5dd0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 2 is a char device
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > fd_prestat_get(fd=Fd(3))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=Bad file descriptor. (Errno::Badf(8))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > fd_write(fd=Fd(1),iovs=*guest 0xe0e8/1)
Capabilities insufficient TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | result=(nwritten=25)
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=No error occurred. System call completed successfully. (Errno::Success(0))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > proc_exit(rval=0)
```

### With required capabilities

Invoking

```
RUST_LOG=wasi_common=trace wasmtime --dir="." zig-cache/bin/wasi_preopens.wasm
```

will successfully run the module's logic to the end and create a `new_file` in `.`. Note that
in this invocation we've added `--dir="."` which essentially means that we explictly give the module
access to `.` path. Anyhow, this is the output you should observe:

```
 DEBUG wasi_common::ctx > WasiCtx inserting entry PendingEntry::Thunk(0x7ffeeba424b8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 0 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 0 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(0)
 DEBUG wasi_common::ctx                 > WasiCtx inserting entry PendingEntry::Thunk(0x7ffeeba424b8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 1 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 1 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(1)
 DEBUG wasi_common::ctx                 > WasiCtx inserting entry PendingEntry::Thunk(0x7ffeeba424b8)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 2 is a char device
 DEBUG wasi_common::sys::unix::oshandle > Host fd 2 is a char device
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(2)
 DEBUG wasi_common::sys::unix::oshandle > Host fd 4 is a directory
 DEBUG wasi_common::sys::unix::oshandle > Host fd 4 is a directory
 DEBUG wasi_common::sys::unix::oshandle > Host fd 4 is a directory
 DEBUG wasi_common::ctx                 > WasiCtx inserted at Fd(3)
 DEBUG wasi_common::old::snapshot_0::ctx > WasiCtx inserting (0, Some(PendingEntry::Thunk(0x7ffeeba47da0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 0 is a char device
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx inserting (1, Some(PendingEntry::Thunk(0x7ffeeba47db0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 1 is a char device
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx inserting (2, Some(PendingEntry::Thunk(0x7ffeeba47dc0)))
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 2 is a char device
 DEBUG wasi_common::old::snapshot_0::sys::unix::entry_impl > Host fd 5 is a directory
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx inserting (3, Entry { file_type: 3, descriptor: OsHandle(OsHandle { file: File { fd: 5, path: "/Users/kubkon/dev/zig-wasi-preopens", read: true, write: false }, dir: None }), rights_base: 264240792, rights_inheriting: 268435455, preopen_path: Some(".") })
 DEBUG wasi_common::old::snapshot_0::ctx                   > WasiCtx entries = {3: Entry { file_type: 3, descriptor: OsHandle(OsHandle { file: File { fd: 5, path: "/Users/kubkon/dev/zig-wasi-preopens", read: true, write: false }, dir: None }), rights_base: 264240792, rights_inheriting: 268435455, preopen_path: Some(".") }, 2: Entry { file_type: 2, descriptor: Stderr, rights_base: 136314954, rights_inheriting: 136314954, preopen_path: None }, 0: Entry { file_type: 2, descriptor: Stdin, rights_base: 136314954, rights_inheriting: 136314954, preopen_path: None }, 1: Entry { file_type: 2, descriptor: Stdout, rights_base: 136314954, rights_inheriting: 136314954, preopen_path: None }}
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > fd_prestat_get(fd=Fd(3))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | result=(buf=Dir(PrestatDir { pr_name_len: 1 }))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=No error occurred. System call completed successfully. (Errno::Success(0))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > fd_prestat_dir_name(fd=Fd(3),path=*guest 0xe1a0,path_len=1)
 TRACE wasi_common::snapshots::wasi_snapshot_preview1      >      | path='.'
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=No error occurred. System call completed successfully. (Errno::Success(0))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > fd_prestat_get(fd=Fd(4))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=Bad file descriptor. (Errno::Badf(8))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > path_open(fd=Fd(3),dirflags=empty (0x0),path=*guest 0x6e0/8,oflags=creat|trunc (0x9),fs_rights_base=fd_datasync|fd_seek|fd_fdstat_set_flags|fd_sync|fd_write|fd_advise|fd_allocate|fd_filestat_set_size|fd_filestat_set_times (0xc001dd),fs_rights_inherting=empty (0x0),fdflags=empty (0x0))
 TRACE wasi_common::snapshots::wasi_snapshot_preview1      >      | needed_rights=EntryRights { base: path_create_file|path_open|path_filestat_set_size (0x82400), inheriting: fd_datasync|fd_seek|fd_fdstat_set_flags|fd_sync|fd_write|fd_advise|fd_allocate|fd_filestat_set_size|fd_filestat_set_times (0xc001dd) }
 TRACE wasi_common::path                                   >      | (path_ptr,path_len)='new_file'
 DEBUG wasi_common::path                                   > path_get cur_path = "new_file"
 DEBUG wasi_common::path                                   > path_get path_stack = []
 TRACE wasi_common::snapshots::wasi_snapshot_preview1      >      | calling path_open impl: read=false, write=true
 DEBUG wasi_common::sys::unix::path                        > path_open dirfd = OsFile { fd: Cell { value: 6 }, dir: RefCell { value: None } }
 DEBUG wasi_common::sys::unix::path                        > path_open path = "new_file"
 DEBUG wasi_common::sys::unix::path                        > path_open oflags = CREAT | NOFOLLOW | WRONLY | TRUNC
 DEBUG wasi_common::sys::unix::path                        > path_open (host) new_fd = 7
 DEBUG wasi_common::sys::unix::oshandle                    > Host fd 7 is a file
 DEBUG wasi_common::sys::unix::oshandle                    > Host fd 7 is a file
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | result=(opened_fd=Fd(4))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           >      | errno=No error occurred. System call completed successfully. (Errno::Success(0))
 TRACE wasi_common::wasi::wasi_snapshot_preview1           > proc_exit(rval=0)
```
