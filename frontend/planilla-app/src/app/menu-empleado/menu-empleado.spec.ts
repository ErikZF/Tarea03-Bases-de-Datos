import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MenuEmpleado } from './menu-empleado';

describe('MenuEmpleado', () => {
  let component: MenuEmpleado;
  let fixture: ComponentFixture<MenuEmpleado>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [MenuEmpleado],
    }).compileComponents();

    fixture = TestBed.createComponent(MenuEmpleado);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
