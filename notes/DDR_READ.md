# DRAM read process

## Set parameters:
- **Number of Banks** = 4
- **Bank Groups** = 4
- **Row per Bank** = 49152
- **Page Size** = 2048 Bytes

This means that **the Row size (Page Size) in each Bank is 2048 Bytes**.

---

## When you read a Column Address, this is what happens:

### 1. Select Bank Group
- Because you have **4 Bank Groups**, the controller will select the target Bank Group based on **address mapping (possible interleaving mechanism)**.

### 2. Select a specific Bank
- You have a total of **4 Banks**, so **Address Mapping** determines which bank to access data.

### 3. Select Row
- In the target Bank, there are **49152 Rows**, and the controller selects a specific **Row through **Row Address** and activates it**.

### 4. Sense Amplifier reads the entire Row
- **The entire Row (2048 Bytes) will be read by the Sense Amp**, but **it does not mean that all 2048 Bytes will be output to the DQ (Data Queue)**, which depends on **Column Address and Burst Length** .

### 5. Column Decoder selects a specific Column
- **How ​​to calculate the number of columns in a Row**:
 - **Column Count = Page Size ÷ Array Prefetch Size**
 - **Assuming Array Prefetch Size = 256 bits (32 Bytes):**
 - **Column Count = 2048 Bytes ÷ 32 Bytes = 64 Columns**
 - Your **Column Address will correspond to one of these 64 Columns**.

### 6. Internal Burst Read
- **One Column Read will not output the entire Page (2048 Bytes), but will determine how much data to output based on the Burst Length. **
- For example:
 - **If Native Burst Length = 16 (16 × 16-bit DQ = 32 Bytes)**
 - **Your DRAM internally reads 32 Bytes at a time, but this comes from the 2048 Bytes Page that has been read in by the Sense Amp. **

### 7. Send data to the controller
- Finally, the data will be from:
 **Bank → Sense Amplifier → Output Buffer → DQ Bus (Data Bus)**