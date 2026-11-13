
/Users/guichafy/Workspaces/DemoGame/.tools/gunbound-client/GunBound.gme:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4d4004: 8a 16                        	movb	(%esi), %dl
  4d4006: 0f b6 c2                     	movzbl	%dl, %eax
  4d4009: 88 91 c4 75 04 00            	movb	%dl, 0x475c4(%ecx)
  4d400f: 99                           	cltd
  4d4010: bf 0b 00 00 00               	movl	$0xb, %edi
  4d4015: f7 ff                        	idivl	%edi
  4d4017: 8b 2d a0 40 54 00            	movl	0x5440a0, %ebp
  4d401d: 83 c4 14                     	addl	$0x14, %esp
  4d4020: 88 1d 15 35 79 00            	movb	%bl, 0x793515
  4d4026: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d402b: 46                           	incl	%esi
  4d402c: 8d 99 7c 55 04 00            	leal	0x4557c(%ecx), %ebx
  4d4032: 8d b9 c8 75 04 00            	leal	0x475c8(%ecx), %edi
  4d4038: 88 91 c4 75 04 00            	movb	%dl, 0x475c4(%ecx)
