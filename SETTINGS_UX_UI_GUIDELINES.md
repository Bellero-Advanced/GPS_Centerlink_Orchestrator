# Settings System — UX/UI Guidelines
# แนวทางการออกแบบ User Experience และ User Interface

## 🎯 UX Principles

### 1. Progressive Disclosure (เปิดเผยข้อมูลทีละขั้น)
- แสดงข้อมูลเฉพาะสิ่งที่จำเป็นก่อน
- ซ่อนฟิลด์ advanced options ในแท็บ "อื่นๆ" หรือ collapse section
- Multi-tab form สำหรับข้อมูลที่มีหลายมิติ

**Example:**
```
Form: เพิ่มยานพาหนะ
├─ Tab 1: ข้อมูลพื้นฐาน (name, license plate, type) ← START HERE
├─ Tab 2: อุปกรณ์ GPS (IMEI, sim, device model)
├─ Tab 3: เอกสาร (insurance, tax, VIN)
└─ Tab 4: บำรุงรักษา (last service, next due)
```

### 2. Consistent Navigation (การนำทางที่สม่ำเสมอ)
- เมนูตั้งค่าในซ้ายมือ (sidebar) — ไม่เปลี่ยนตำแหน่ง
- Breadcrumb บน PageHeader: ตั้งค่า > จัดการทรัพย์สิน > แก้ไข รถ-001
- ปุ่ม "กลับ" ชัดเจน (ไอคอน arrow-left + ข้อความ)

### 3. Immediate Feedback (ตอบสนองทันที)
- Save button → show loading spinner → toast "บันทึกสำเร็จ ✓" (1.5s)
- Delete → ConfirmModal → loading → toast "ลบเรียบร้อย"
- Form validation → real-time (show error on blur, not on submit)

### 4. Prevent Errors (ป้องกันข้อผิดพลาด)
- Required fields มี `*` สีแดง
- Input mask สำหรับ phone (0xx-xxx-xxxx), IMEI (15 digits)
- ConfirmModal สำหรับ destructive actions (ลบ, ระงับ)
- Disable submit button เมื่อ form invalid

### 5. User Control (ผู้ใช้ควบคุมได้)
- ปุ่ม "ยกเลิก" ทุก modal (ESC key closes modal)
- "ลบ" สามารถ undo ได้ (soft delete + restore)
- "แก้ไข" เปิดข้อมูลเดิม ไม่ใช่ blank form

---

## 🎨 UI Design Patterns

### Color System (สี)

**Status Colors (ต้องใช้สีเดียวกับ vehicle status):**
```css
--status-active:   #22c55e;  /* เขียว — ใช้งาน */
--status-inactive: #94a3b8;  /* เทา — ปิดใช้งาน */
--status-pending:  #f59e0b;  /* ส้ม — รอดำเนินการ */
--status-error:    #ef4444;  /* แดง — ผิดพลาด */
```

**Form Colors:**
```css
--input-border:    var(--border);           /* ขอบ input ปกติ */
--input-border-focus: var(--brand);         /* ขอบ input เมื่อ focus */
--input-border-error: var(--critical);      /* ขอบ input เมื่อ error */
--input-bg:        var(--surface-2);        /* พื้นหลัง input */
```

**Button Colors:**
```css
/* Primary Button */
.btn-primary {
  background: var(--brand);
  color: #fff;
  border: none;
}

/* Secondary Button */
.btn-secondary {
  background: var(--surface-2);
  color: var(--ink-2);
  border: 1px solid var(--border);
}

/* Danger Button */
.btn-danger {
  background: var(--critical);
  color: #fff;
  border: none;
}
```

---

### Typography (ตัวอักษร)

**Font Stack:**
- Thai: Sarabun (300, 400, 600, 700)
- English/Numbers: Inter (300, 400, 500, 600, 700)
- Monospace (IMEI, coordinates): JetBrains Mono

**Font Sizes:**
```css
--text-xs:    11px;   /* helper text, badges */
--text-sm:    13px;   /* input labels, table cells */
--text-base:  15px;   /* body text, buttons */
--text-lg:    17px;   /* section labels */
--text-xl:    20px;   /* PageHeader title */
--text-2xl:   24px;   /* Modal title */
```

**Font Weights:**
- 300: helper text
- 400: body text
- 500: input labels
- 600: section labels, buttons
- 700: headings

---

### Spacing (ระยะห่าง)

**Consistent spacing scale (4px base):**
```css
--space-1:   4px;
--space-2:   8px;
--space-3:   12px;
--space-4:   16px;
--space-5:   20px;
--space-6:   24px;
--space-8:   32px;
--space-10:  40px;
--space-12:  48px;
```

**Form Field Spacing:**
- Between fields: 16px (space-4)
- Between sections: 32px (space-8)
- Between form and buttons: 24px (space-6)

**Card Padding:**
- Small card: 16px (space-4)
- Medium card: 20px (space-5)
- Large card: 24px (space-6)

---

### Form Components

#### Input Field
```tsx
<div className="form-field">
  <label className="form-label">
    ชื่อยานพาหนะ <span className="text-critical">*</span>
  </label>
  <input
    type="text"
    className="form-input"
    placeholder="เช่น รถ-001"
    required
  />
  {error && <p className="form-error">{error}</p>}
  <p className="form-hint">ชื่อที่แสดงบนแผนที่และรายงาน</p>
</div>
```

**Styles:**
```css
.form-field {
  margin-bottom: var(--space-4);
}

.form-label {
  display: block;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-2);
  margin-bottom: var(--space-2);
}

.form-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface-2);
  font-size: var(--text-base);
  transition: border 150ms;
}

.form-input:focus {
  outline: none;
  border-color: var(--brand);
  box-shadow: 0 0 0 3px rgba(29, 122, 237, 0.1);
}

.form-input.error {
  border-color: var(--critical);
}

.form-error {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--critical);
}

.form-hint {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--ink-4);
}
```

---

#### Select Dropdown
```tsx
<div className="form-field">
  <label className="form-label">ประเภท</label>
  <select className="form-select">
    <option value="">เลือกประเภท...</option>
    <option value="truck">รถบรรทุก</option>
    <option value="van">รถตู้</option>
    <option value="car">รถเก๋ง</option>
  </select>
</div>
```

**Styles:**
```css
.form-select {
  width: 100%;
  padding: 10px 36px 10px 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface-2);
  font-size: var(--text-base);
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,..."); /* chevron-down icon */
  background-repeat: no-repeat;
  background-position: right 12px center;
}
```

---

#### Radio Buttons
```tsx
<div className="form-field">
  <label className="form-label">สถานะ</label>
  <div className="radio-group">
    <label className="radio-option">
      <input type="radio" name="status" value="active" />
      <span>ใช้งาน</span>
    </label>
    <label className="radio-option">
      <input type="radio" name="status" value="inactive" />
      <span>ปิดใช้งาน</span>
    </label>
  </div>
</div>
```

**Styles:**
```css
.radio-group {
  display: flex;
  gap: var(--space-4);
}

.radio-option {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 8px;
  transition: background 150ms;
}

.radio-option:hover {
  background: var(--surface-2);
}

.radio-option input[type="radio"] {
  width: 16px;
  height: 16px;
  cursor: pointer;
}
```

---

#### Checkbox
```tsx
<label className="checkbox-option">
  <input type="checkbox" />
  <span>ส่งอีเมลแจ้งเตือน</span>
</label>
```

**Styles:**
```css
.checkbox-option {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
}

.checkbox-option input[type="checkbox"] {
  width: 16px;
  height: 16px;
  cursor: pointer;
}
```

---

### Modal Layout

```tsx
<div className="modal-overlay" onClick={onClose}>
  <div className="modal-content" onClick={(e) => e.stopPropagation()}>
    {/* Header */}
    <div className="modal-header">
      <h2 className="modal-title">เพิ่มยานพาหนะใหม่</h2>
      <button className="modal-close" onClick={onClose}>
        <X size={20} />
      </button>
    </div>

    {/* Body */}
    <div className="modal-body">
      <form>{/* fields */}</form>
    </div>

    {/* Footer */}
    <div className="modal-footer">
      <button className="btn-secondary" onClick={onClose}>ยกเลิก</button>
      <button className="btn-primary" type="submit">บันทึก</button>
    </div>
  </div>
</div>
```

**Styles:**
```css
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-content {
  background: var(--surface-0);
  border-radius: 12px;
  box-shadow: var(--shadow-lg);
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--border);
}

.modal-title {
  font-size: var(--text-2xl);
  font-weight: 600;
  color: var(--ink-1);
}

.modal-close {
  padding: 4px;
  border: none;
  background: transparent;
  color: var(--ink-3);
  cursor: pointer;
  border-radius: 4px;
  transition: background 150ms;
}

.modal-close:hover {
  background: var(--surface-2);
}

.modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.modal-footer {
  display: flex;
  gap: var(--space-3);
  justify-content: flex-end;
  padding: 16px 24px;
  border-top: 1px solid var(--border);
}
```

---

### Table Layout

```tsx
<div className="table-container">
  <table className="data-table">
    <thead>
      <tr>
        <th>ชื่อ</th>
        <th>ป้ายทะเบียน</th>
        <th>สถานะ</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>รถ-001</td>
        <td>กข 1234</td>
        <td><span className="chip chip-success">ใช้งาน</span></td>
        <td>
          <button className="btn-icon">แก้ไข</button>
          <button className="btn-icon">ลบ</button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

**Styles:**
```css
.table-container {
  overflow-x: auto;
  border-radius: 12px;
  border: 1px solid var(--border);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table thead {
  background: var(--surface-2);
  position: sticky;
  top: 0;
  z-index: 1;
}

.data-table th {
  padding: 12px 16px;
  text-align: left;
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-2);
  border-bottom: 1px solid var(--border);
}

.data-table td {
  padding: 12px 16px;
  font-size: var(--text-sm);
  color: var(--ink-2);
  border-bottom: 1px solid var(--border);
}

.data-table tbody tr:hover {
  background: var(--surface-1);
}

.data-table tbody tr:last-child td {
  border-bottom: none;
}
```

---

### Status Chips

```tsx
<span className="chip chip-success">ใช้งาน</span>
<span className="chip chip-warning">รอดำเนินการ</span>
<span className="chip chip-danger">ปิดใช้งาน</span>
<span className="chip chip-neutral">ระงับ</span>
```

**Styles:**
```css
.chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: var(--text-xs);
  font-weight: 500;
}

.chip-success {
  background: rgba(34, 197, 94, 0.1);
  color: #16a34a;
}

.chip-warning {
  background: rgba(245, 158, 11, 0.1);
  color: #d97706;
}

.chip-danger {
  background: rgba(239, 68, 68, 0.1);
  color: #dc2626;
}

.chip-neutral {
  background: rgba(148, 163, 184, 0.1);
  color: #64748b;
}
```

---

## ♿ Accessibility (A11Y)

### 1. Keyboard Navigation
- Tab key: move between inputs
- Shift+Tab: move backwards
- Enter: submit form (when inside form)
- Escape: close modal
- Arrow keys: navigate select dropdown

### 2. Screen Reader Support
- All images have `alt` text
- Buttons have `aria-label` when no text
- Form errors announced with `aria-live="polite"`
- Modal has `role="dialog"` and `aria-labelledby`

### 3. Focus Management
- Modal: focus first input on open, trap focus inside
- Delete confirm: focus "ยกเลิก" button (safe default)
- After delete: focus return to previous element

### 4. Color Contrast
- Text/background: minimum 4.5:1 ratio (WCAG AA)
- Interactive elements: 3:1 ratio
- Test with tools: axe DevTools, Lighthouse

---

## 📱 Responsive Design

### Breakpoints
```css
/* Mobile: < 640px */
@media (max-width: 639px) {
  .modal-content { max-width: 100%; }
  .form-field { margin-bottom: var(--space-3); }
  .table-container { font-size: var(--text-xs); }
}

/* Tablet: 640px - 1023px */
@media (min-width: 640px) and (max-width: 1023px) {
  .modal-content { max-width: 540px; }
}

/* Desktop: >= 1024px */
@media (min-width: 1024px) {
  .modal-content { max-width: 600px; }
}
```

### Mobile Considerations
- Tap targets: minimum 44×44px
- Stack form fields vertically (no grid on mobile)
- Tables: horizontal scroll (not responsive collapse)
- Modals: full-screen on mobile (< 640px)

---

## ✅ Checklist Before Release

- [ ] All forms validated (required fields, format, length)
- [ ] All modals closable (X button + ESC key + overlay click)
- [ ] All tables sortable (click column header)
- [ ] All lists searchable (search input at top)
- [ ] Loading states show spinner
- [ ] Error states show toast + retry
- [ ] Empty states show EmptyState component
- [ ] Success actions show toast (บันทึกสำเร็จ ✓)
- [ ] Dark mode works (all colors use CSS vars)
- [ ] Mobile responsive (test 375px width)
- [ ] Thai text displays correctly (Sarabun font loaded)
- [ ] Keyboard navigation works (Tab, Enter, ESC)
- [ ] Screen reader friendly (aria labels)

