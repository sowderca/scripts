rem == CreateRecoveryPartitions-UEFI.txt ==
select disk 0
select partition 3
assign letter="W"
rem == extend the Windows partition ==
shrink minimum=500
extend
rem ==    b. Create space for the recovery tools  
shrink minimum=500
rem       ** NOTE: Update this size to match the
rem                size of the recovery tools 
rem                (winre.wim)                 **
rem === Create Recovery partition ======================
create partition primary
format quick fs=ntfs label="Recovery"
assign letter="R"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
list volume
exit