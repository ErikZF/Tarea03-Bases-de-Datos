import { TestBed } from '@angular/core/testing';

import { Planilla } from './planilla';

describe('Planilla', () => {
  let service: Planilla;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(Planilla);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
