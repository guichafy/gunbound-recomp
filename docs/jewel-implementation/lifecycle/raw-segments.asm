  40d9b8: 6a 0a                        	pushl	$0xa
  40d9ba: bf 40 ba e9 00               	movl	$0xe9ba40, %edi         # imm = 0xE9BA40
  40d9bf: e8 bc c9 ff ff               	calll	0x40a380 <.text+0x9380>
  40d9c4: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  40d9c9: ff d3                        	calll	*%ebx
  40d9cb: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  40d9d0: ff d6                        	calll	*%esi
  40d9d2: 6a 0f                        	pushl	$0xf
  40d9d4: bf f0 4b 79 00               	movl	$0x794bf0, %edi         # imm = 0x794BF0
  40d9d9: e8 a2 c9 ff ff               	calll	0x40a380 <.text+0x9380>
  4d4501: 8b 06                        	movl	(%esi), %eax
  4d4503: 50                           	pushl	%eax
  4d4504: 52                           	pushl	%edx
  4d4505: e8 46 b8 f4 ff               	calll	0x41fd50 <.text+0x1ed50>
  4d450a: 8b 0e                        	movl	(%esi), %ecx
  4d450c: 8b 3d 84 34 5b 00            	movl	0x5b3484, %edi
  4d4512: 8b 1d a0 40 54 00            	movl	0x5440a0, %ebx
  4d4518: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d451d: 89 0d 80 34 5b 00            	movl	%ecx, 0x5b3480
  4d4523: 83 c6 04                     	addl	$0x4, %esi
  4d4526: 81 c7 94 7f 6a 00            	addl	$0x6a7f94, %edi         # imm = 0x6A7F94
  4d452c: ff d3                        	calll	*%ebx
  4d452e: 6a 00                        	pushl	$0x0
  4d4530: e8 4b 5e f3 ff               	calll	0x40a380 <.text+0x9380>
  4d4535: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d453a: ff 15 9c 40 54 00            	calll	*0x54409c
  4d4540: 8b 3d 84 34 5b 00            	movl	0x5b3484, %edi
  4d4546: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d454b: 81 c7 90 7f 6a 00            	addl	$0x6a7f90, %edi         # imm = 0x6A7F90
  4d4551: ff d3                        	calll	*%ebx
  4d4553: e8 f7 16 05 00               	calll	0x525c4f <.text+0x124c4f>
  4d4558: 25 ff 00 00 80               	andl	$0x800000ff, %eax       # imm = 0x800000FF
  4d455d: 79 07                        	jns	0x4d4566 <.text+0xd3566>
  4d455f: 48                           	decl	%eax
  4d4560: 0d 00 ff ff ff               	orl	$0xffffff00, %eax       # imm = 0xFFFFFF00
  4d4565: 40                           	incl	%eax
  4d4566: 88 07                        	movb	%al, (%edi)
  4d4568: e8 e2 16 05 00               	calll	0x525c4f <.text+0x124c4f>
  4d456d: 25 ff 00 00 80               	andl	$0x800000ff, %eax       # imm = 0x800000FF
  4d4572: 79 07                        	jns	0x4d457b <.text+0xd357b>
  4d4574: 48                           	decl	%eax
  4d4575: 0d 00 ff ff ff               	orl	$0xffffff00, %eax       # imm = 0xFFFFFF00
  4d457a: 40                           	incl	%eax
  4d457b: 8a 1f                        	movb	(%edi), %bl
  4d457d: 33 d2                        	xorl	%edx, %edx
  4d457f: 8a d3                        	movb	%bl, %dl
  4d4581: 88 47 01                     	movb	%al, 0x1(%edi)
  4d4584: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d4589: 83 e2 07                     	andl	$0x7, %edx
  4d458c: 8b ea                        	movl	%edx, %ebp
  4d458e: 8b cd                        	movl	%ebp, %ecx
  4d4590: 8b 2d 9c 40 54 00            	movl	0x54409c, %ebp
  4d4596: b2 01                        	movb	$0x1, %dl
  4d4598: d2 e2                        	shlb	%cl, %dl
  4d459a: f6 d2                        	notb	%dl
  4d459c: 22 d0                        	andb	%al, %dl
  4d459e: 32 c0                        	xorb	%al, %al
  4d45a0: d2 e0                        	shlb	%cl, %al
  4d45a2: 0a d0                        	orb	%al, %dl
  4d45a4: 88 57 01                     	movb	%dl, 0x1(%edi)
  4d45a7: 02 d3                        	addb	%bl, %dl
  4d45a9: 80 ea 34                     	subb	$0x34, %dl
  4d45ac: 88 57 02                     	movb	%dl, 0x2(%edi)
  4d45af: ff d5                        	calll	*%ebp
  4d45b1: 8b 3d 84 34 5b 00            	movl	0x5b3484, %edi
  4d45b7: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d45bc: 81 c7 54 53 04 00            	addl	$0x45354, %edi          # imm = 0x45354
  4d45c2: ff 15 a0 40 54 00            	calll	*0x5440a0
  4d45c8: 8b c7                        	movl	%edi, %eax
  4d45ca: e8 11 5d f3 ff               	calll	0x40a2e0 <.text+0x92e0>
  4d45cf: 83 f8 03                     	cmpl	$0x3, %eax
  4d45d2: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d45d7: 0f 94 c3                     	sete	%bl
  4d45da: ff d5                        	calll	*%ebp
  4d45dc: 84 db                        	testb	%bl, %bl
  4d45de: 74 71                        	je	0x4d4651 <.text+0xd3651>
  4d45e0: 33 db                        	xorl	%ebx, %ebx
  4d45e2: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  4d45e8: 0f b7 3e                     	movzwl	(%esi), %edi
  4d45eb: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d45f0: 8d ac 0b b8 81 6a 00         	leal	0x6a81b8(%ebx,%ecx), %ebp
  4d45f7: ff 15 a0 40 54 00            	calll	*0x5440a0
  4d45fd: 57                           	pushl	%edi
  4d45fe: 8b fd                        	movl	%ebp, %edi
  4d4600: e8 7b 5d f3 ff               	calll	0x40a380 <.text+0x9380>
  4d4605: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d460a: ff 15 9c 40 54 00            	calll	*0x54409c
  4d4610: 8b 15 84 34 5b 00            	movl	0x5b3484, %edx
  4d4616: 0f b6 7e 02                  	movzbl	0x2(%esi), %edi
  4d461a: 83 c6 02                     	addl	$0x2, %esi
  4d461d: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d4622: 8d ac 13 90 8e 6a 00         	leal	0x6a8e90(%ebx,%edx), %ebp
  4d4629: ff 15 a0 40 54 00            	calll	*0x5440a0
  4d462f: 57                           	pushl	%edi
  4d4630: 8b fd                        	movl	%ebp, %edi
  4d4632: e8 49 5d f3 ff               	calll	0x40a380 <.text+0x9380>
  4d4637: 68 68 90 5a 00               	pushl	$0x5a9068               # imm = 0x5A9068
  4d463c: ff 15 9c 40 54 00            	calll	*0x54409c
  4d4642: 81 c3 24 02 00 00            	addl	$0x224, %ebx            # imm = 0x224
  4d4648: 46                           	incl	%esi
  4d4649: 81 fb d8 0c 00 00            	cmpl	$0xcd8, %ebx            # imm = 0xCD8
  4d464f: 7c 91                        	jl	0x4d45e2 <.text+0xd35e2>
  525c4f: e8 80 48 00 00               	calll	0x52a4d4 <.text+0x1294d4>
  525c54: 8b 48 14                     	movl	0x14(%eax), %ecx
  525c57: 69 c9 fd 43 03 00            	imull	$0x343fd, %ecx, %ecx    # imm = 0x343FD
  525c5d: 81 c1 c3 9e 26 00            	addl	$0x269ec3, %ecx         # imm = 0x269EC3
  525c63: 89 48 14                     	movl	%ecx, 0x14(%eax)
  525c66: 8b c1                        	movl	%ecx, %eax
  525c68: c1 e8 10                     	shrl	$0x10, %eax
  525c6b: 25 ff 7f 00 00               	andl	$0x7fff, %eax           # imm = 0x7FFF
  525c70: c3                           	retl
