extern kmain
global start

KERNEL_BASE equ 0xFFFFC00000000000

section .bootstrap
bits 32
start:
	; make Multiboot information available to Rust as first argument
	mov edi, ebx

	; Check that we are loaded by a multiboot2-compliant bootloader
	call check_multiboot2

	; map first and 384th PML4 entry to PDP table
	; (so virtual address 0xFFFFC00000000000 = physical address 0)
	mov eax, pdp_table - KERNEL_BASE
	or eax, 0b11 ; present + writable
	mov [pml4_table - KERNEL_BASE], eax
	mov [pml4_table - KERNEL_BASE + 384 * 8], eax

	; map first PDP entry to PD table
	mov eax, pd_table - KERNEL_BASE
	or eax, 0b11
	mov [pdp_table - KERNEL_BASE], eax

	; map each PD entry to a huge (2MiB) page
	mov ecx, 0
.loop:
	mov eax, 0x200000
	mul ecx
	or eax, 0b10000011 ; present + writable + huge
	mov [pd_table - KERNEL_BASE + ecx * 8], eax
	inc ecx
	cmp ecx, 512
	jne .loop

	; load PML4 to cr3 register
	mov eax, pml4_table - KERNEL_BASE
	mov cr3, eax

	; enable PAE flag in cr4
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set the long mode bit in the EFER MSR
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; enable paging in the cr0 register
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	; load GDT
	lgdt [gdt64.pointer - KERNEL_BASE]

	; update selectors
	mov ax, gdt64.data
	mov ss, ax
	mov ds, ax
	mov es, ax

	jmp gdt64.code:start64

check_multiboot2:
	; Check if EAX contains the magic number as specified by the multiboot2 spec
	cmp eax, 0x36d76289
	jne .no_multiboot2
	ret
.no_multiboot2:
	mov esi, no_multiboot2_error - KERNEL_BASE
	call print_error

print_error:
	mov edi, 0xb8000
.loop:
	cmp byte [esi], 0
	jz .done
	movsb
	mov byte [edi], 0x04 ; red text on black background
	inc edi
	jmp .loop
.done:
	hlt
	jmp .done

bits 64
start64:
	; set stack pointer
	mov rsp, stack_top
	; jump into Rust
	mov rax, kmain
	jmp rax

ONE_PAGE equ 4096
STACK_SIZE equ 1024 * 16 ; 16 KiB

section .bss
align 4096
pml4_table:
	resb ONE_PAGE
pdp_table:
	resb ONE_PAGE
pd_table:
	resb ONE_PAGE
page_table:
	resb ONE_PAGE
stack_bottom:
	resb STACK_SIZE
stack_top:

section .rodata
align 8
gdt64:
	dq 0
.code: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41)
.pointer:
	dw $ - gdt64 - 1
	dq gdt64

no_multiboot2_error: db "Boot loader is not multiboot2 compliant!",0
