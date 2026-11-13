
/Users/guichafy/Workspaces/DemoGame/.tools/gunbound-client/GunBound.gme:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4bb730: 81 ec 9c 00 00 00            	subl	$0x9c, %esp
  4bb736: 53                           	pushl	%ebx
  4bb737: 8b 1d a0 40 54 00            	movl	0x5440a0, %ebx
  4bb73d: 55                           	pushl	%ebp
  4bb73e: 56                           	pushl	%esi
  4bb73f: 57                           	pushl	%edi
  4bb740: 8b e9                        	movl	%ecx, %ebp
  4bb742: c7 85 c4 23 00 00 ff ff ff ff	movl	$0xffffffff, 0x23c4(%ebp) # imm = 0xFFFFFFFF
  4bb74c: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4bb751: c6 05 8c 76 7a 00 01         	movb	$0x1, 0x7a768c
  4bb758: ff d3                        	calll	*%ebx
  4bb75a: e8 f0 a4 06 00               	calll	0x525c4f <.text+0x124c4f>
  4bb75f: 25 ff 00 00 80               	andl	$0x800000ff, %eax       # imm = 0x800000FF
  4bb764: 79 07                        	jns	0x4bb76d <.text+0xba76d>
  4bb766: 48                           	decl	%eax
  4bb767: 0d 00 ff ff ff               	orl	$0xffffff00, %eax       # imm = 0xFFFFFF00
  4bb76c: 40                           	incl	%eax
  4bb76d: 88 85 c8 23 00 00            	movb	%al, 0x23c8(%ebp)
  4bb773: e8 d7 a4 06 00               	calll	0x525c4f <.text+0x124c4f>
  4bb778: 25 ff 00 00 80               	andl	$0x800000ff, %eax       # imm = 0x800000FF
  4bb77d: 79 07                        	jns	0x4bb786 <.text+0xba786>
  4bb77f: 48                           	decl	%eax
  4bb780: 0d 00 ff ff ff               	orl	$0xffffff00, %eax       # imm = 0xFFFFFF00
  4bb785: 40                           	incl	%eax
  4bb786: 8a 95 c8 23 00 00            	movb	0x23c8(%ebp), %dl
  4bb78c: 88 85 c9 23 00 00            	movb	%al, 0x23c9(%ebp)
  4bb792: 89 44 24 1c                  	movl	%eax, 0x1c(%esp)
  4bb796: 33 c0                        	xorl	%eax, %eax
  4bb798: 8a c2                        	movb	%dl, %al
  4bb79a: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4bb79f: 83 e0 07                     	andl	$0x7, %eax
  4bb7a2: 8b f0                        	movl	%eax, %esi
  4bb7a4: 8b ce                        	movl	%esi, %ecx
  4bb7a6: 8b 35 9c 40 54 00            	movl	0x54409c, %esi
  4bb7ac: b0 01                        	movb	$0x1, %al
  4bb7ae: d2 e0                        	shlb	%cl, %al
  4bb7b0: 8a c8                        	movb	%al, %cl
  4bb7b2: 88 44 24 17                  	movb	%al, 0x17(%esp)
  4bb7b6: 8a 44 24 20                  	movb	0x20(%esp), %al
  4bb7ba: f6 d1                        	notb	%cl
  4bb7bc: 22 c8                        	andb	%al, %cl
  4bb7be: 0a 4c 24 17                  	orb	0x17(%esp), %cl
  4bb7c2: 02 d1                        	addb	%cl, %dl
  4bb7c4: 80 ea 34                     	subb	$0x34, %dl
  4bb7c7: 88 8d c9 23 00 00            	movb	%cl, 0x23c9(%ebp)
  4bb7cd: 88 95 ca 23 00 00            	movb	%dl, 0x23ca(%ebp)
  4bb7d3: ff d6                        	calll	*%esi
  4bb7d5: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  4bb7db: 0f b6 91 c4 75 04 00         	movzbl	0x475c4(%ecx), %edx
  4bb7e2: 52                           	pushl	%edx
  4bb7e3: 8d 44 24 30                  	leal	0x30(%esp), %eax
  4bb7e7: 68 c0 69 55 00               	pushl	$0x5569c0               # imm = 0x5569C0
  4bb7ec: 50                           	pushl	%eax
  4bb7ed: e8 ec 9d 06 00               	calll	0x5255de <.text+0x1245de>
  4bb7f2: 6a 01                        	pushl	$0x1
  4bb7f4: 8d 7c 24 3c                  	leal	0x3c(%esp), %edi
  4bb7f8: e8 33 32 03 00               	calll	0x4eea30 <.text+0xeda30>
  4bb7fd: 83 c4 10                     	addl	$0x10, %esp
  4bb800: 84 c0                        	testb	%al, %al
  4bb802: 75 26                        	jne	0x4bb82a <.text+0xba82a>
  4bb804: e8 46 a4 06 00               	calll	0x525c4f <.text+0x124c4f>
  4bb809: 99                           	cltd
  4bb80a: b9 06 00 00 00               	movl	$0x6, %ecx
  4bb80f: f7 f9                        	idivl	%ecx
  4bb811: 42                           	incl	%edx
  4bb812: 52                           	pushl	%edx
  4bb813: 8b d7                        	movl	%edi, %edx
  4bb815: 68 c0 69 55 00               	pushl	$0x5569c0               # imm = 0x5569C0
  4bb81a: 52                           	pushl	%edx
  4bb81b: e8 be 9d 06 00               	calll	0x5255de <.text+0x1245de>
  4bb820: 6a 01                        	pushl	$0x1
  4bb822: e8 09 32 03 00               	calll	0x4eea30 <.text+0xeda30>
  4bb827: 83 c4 10                     	addl	$0x10, %esp
  4bb82a: a1 84 34 5b 00               	movl	0x5b3484, %eax
