c
c     Copyright (c) 2002-2010, Boyce Griffith
c     All rights reserved.
c
c     Redistribution and use in source and binary forms, with or without
c     modification, are permitted provided that the following conditions
c     are met:
c
c        * Redistributions of source code must retain the above
c          copyright notice, this list of conditions and the following
c          disclaimer.
c
c        * Redistributions in binary form must reproduce the above
c          copyright notice, this list of conditions and the following
c          disclaimer in the documentation and/or other materials
c          provided with the distribution.
c
c        * Neither the name of New York University nor the names of its
c          contributors may be used to endorse or promote products
c          derived from this software without specific prior written
c          permission.
c
c     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
c     CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
c     INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
c     MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
c     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
c     BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
c     EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
c     TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
c     DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
c     ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
c     TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
c     THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
c     SUCH DAMAGE.
c
define(NDIM,3)dnl
define(REAL,`double precision')dnl
define(INTEGER,`integer')dnl
include(SAMRAI_FORTDIR/pdat_m4arrdim3d.i)dnl
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Interpolate u onto V at the positions specified by X using the IB
c     3-point delta function.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_3_interp3d(
     &     dx,x_lower,x_upper,depth,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     use_alt_one_sided_delta,
     &     nugc0,nugc1,nugc2,
     &     u,
     &     indices,Xshift,nindices,
     &     X,V)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_3_delta
c
c     Input.
c
      INTEGER depth
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2
      INTEGER nindices

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)
      INTEGER use_alt_one_sided_delta(0:NDIM-1)

      INTEGER indices(0:nindices-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,l,s

      REAL X_cell(0:NDIM-1),w0(0:2),w1(0:2),w2(0:2)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 3-point delta function to interpolate u onto V.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard interpolation stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            ic_lower(d) = ic_center(d)-1
            ic_upper(d) = ic_center(d)+1
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard interpolation weights.
c
CDEC$ LOOP COUNT(3)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_3_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(3)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_3_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(3)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_3_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special interpolation weights are needed to
c     handle physical boundary conditions.
c
         do d = 0,NDIM-1

            touches_lower_bdry(d) = .false.
            if ( patch_touches_lower_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (X(d,s) - x_lower(d) .lt. 1.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               endif
            endif

            touches_upper_bdry(d) = .false.
            if ( patch_touches_upper_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (x_upper(d) - X(d,s) .lt. 1.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               endif
            endif

         enddo
c
c     Modify the interpolation stencil and weights near physical
c     boundaries.
c
         if (touches_lower_bdry(0)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(0)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif

         if (touches_lower_bdry(1)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(1)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif

         if (touches_lower_bdry(2)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(2)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif
c
c     Interpolate u onto V.
c
         do d = 0,depth-1
            V(d,s) = 0.d0
CDEC$ LOOP COUNT(3)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(3)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(3)
                  do ic0 = ic_lower(0),ic_upper(0)
                     V(d,s) = V(d,s)
     &                    +w0(ic0-ic_lower(0))
     &                    *w1(ic1-ic_lower(1))
     &                    *w2(ic2-ic_lower(2))
     &                    *u(ic0,ic1,ic2,d)
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Spread V onto u at the positions specified by X using the IB
c     3-point delta function using standard (double) precision
c     accumulation on the Cartesian grid.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_3_spread3d(
     &     dx,x_lower,x_upper,depth,
     &     indices,Xshift,nindices,
     &     X,V,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     use_alt_one_sided_delta,
     &     nugc0,nugc1,nugc2,
     &     u)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_3_delta
c
c     Input.
c
      INTEGER depth
      INTEGER nindices
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2

      INTEGER indices(0:nindices-1)

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)
      INTEGER use_alt_one_sided_delta(0:NDIM-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,l,s

      REAL X_cell(0:NDIM-1),w0(0:2),w1(0:2),w2(0:2)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 3-point delta function to spread V onto u.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard spreading stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            ic_lower(d) = ic_center(d)-1
            ic_upper(d) = ic_center(d)+1
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard spreading weights.
c
CDEC$ LOOP COUNT(3)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_3_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(3)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_3_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(3)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_3_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special spreading weights are needed to handle
c     physical boundary conditions.
c
         do d = 0,NDIM-1

            touches_lower_bdry(d) = .false.
            if ( patch_touches_lower_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (X(d,s) - x_lower(d) .lt. 1.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               endif
            endif

            touches_upper_bdry(d) = .false.
            if ( patch_touches_upper_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (x_upper(d) - X(d,s) .lt. 1.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               endif
            endif

         enddo
c
c     Modify the spreading stencil and weights near physical boundaries.
c
         if (touches_lower_bdry(0)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(0)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif

         if (touches_lower_bdry(1)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(1)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif

         if (touches_lower_bdry(2)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         elseif (touches_upper_bdry(2)) then
            print *,'error: not supported for IB_3 delta function...'
            call abort
         endif
c
c     Spread V onto u.
c
         do d = 0,depth-1
CDEC$ LOOP COUNT(3)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(3)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(3)
                  do ic0 = ic_lower(0),ic_upper(0)
                     u(ic0,ic1,ic2,d) = u(ic0,ic1,ic2,d)+(
     &                    w0(ic0-ic_lower(0))*
     &                    w1(ic1-ic_lower(1))*
     &                    w2(ic2-ic_lower(2))*
     &                    V(d,s)/(dx(0)*dx(1)*dx(2)))
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Interpolate u onto V at the positions specified by X using the IB
c     4-point delta function.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_4_interp3d(
     &     dx,x_lower,x_upper,depth,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     use_alt_one_sided_delta,
     &     nugc0,nugc1,nugc2,
     &     u,
     &     indices,Xshift,nindices,
     &     X,V)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_4_delta
c
c     Input.
c
      INTEGER depth
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2
      INTEGER nindices

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)
      INTEGER use_alt_one_sided_delta(0:NDIM-1)

      INTEGER indices(0:nindices-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:3),w0(0:3),w1(0:3),w2(0:3)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 4-point delta function to interpolate u onto V.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard interpolation stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+1
            else
               ic_lower(d) = ic_center(d)-1
               ic_upper(d) = ic_center(d)+2
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard interpolation weights.
c
CDEC$ LOOP COUNT(4)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_4_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(4)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_4_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(4)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_4_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special interpolation weights are needed to
c     handle physical boundary conditions.
c
         do d = 0,NDIM-1

            touches_lower_bdry(d) = .false.
            if ( patch_touches_lower_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (X(d,s) - x_lower(d) .lt. 1.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               endif
            endif

            touches_upper_bdry(d) = .false.
            if ( patch_touches_upper_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (x_upper(d) - X(d,s) .lt. 1.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               endif
            endif

         enddo
c
c     Modify the interpolation stencil and weights near physical
c     boundaries.
c
         if (touches_lower_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0
               ic_upper(0) = ifirst0+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0+1
               ic_upper(0) = ifirst0+4
            endif
         elseif (touches_upper_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-3
               ic_upper(0) = ilast0
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-4
               ic_upper(0) = ilast0-1
            endif
            do k = 0,3
               w0(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1
               ic_upper(1) = ifirst1+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1+1
               ic_upper(1) = ifirst1+4
            endif
         elseif (touches_upper_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-3
               ic_upper(1) = ilast1
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-4
               ic_upper(1) = ilast1-1
            endif
            do k = 0,3
               w1(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2
               ic_upper(2) = ifirst2+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2+1
               ic_upper(2) = ifirst2+4
            endif
         elseif (touches_upper_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-3
               ic_upper(2) = ilast2
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-4
               ic_upper(2) = ilast2-1
            endif
            do k = 0,3
               w2(3-k) = f(k)
            enddo
         endif
c
c     Interpolate u onto V.
c
         do d = 0,depth-1
            V(d,s) = 0.d0
CDEC$ LOOP COUNT(4)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(4)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(4)
                  do ic0 = ic_lower(0),ic_upper(0)
                     V(d,s) = V(d,s)
     &                    +w0(ic0-ic_lower(0))
     &                    *w1(ic1-ic_lower(1))
     &                    *w2(ic2-ic_lower(2))
     &                    *u(ic0,ic1,ic2,d)
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Spread V onto u at the positions specified by X using the IB
c     4-point delta function using standard (double) precision
c     accumulation on the Cartesian grid.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_4_spread3d(
     &     dx,x_lower,x_upper,depth,
     &     indices,Xshift,nindices,
     &     X,V,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     use_alt_one_sided_delta,
     &     nugc0,nugc1,nugc2,
     &     u)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_4_delta
c
c     Input.
c
      INTEGER depth
      INTEGER nindices
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2

      INTEGER indices(0:nindices-1)

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)
      INTEGER use_alt_one_sided_delta(0:NDIM-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:3),w0(0:3),w1(0:3),w2(0:3)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 4-point delta function to spread V onto u.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard spreading stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+1
            else
               ic_lower(d) = ic_center(d)-1
               ic_upper(d) = ic_center(d)+2
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard spreading weights.
c
CDEC$ LOOP COUNT(4)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_4_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(4)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_4_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(4)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_4_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special spreading weights are needed to handle
c     physical boundary conditions.
c
         do d = 0,NDIM-1

            touches_lower_bdry(d) = .false.
            if ( patch_touches_lower_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (X(d,s) - x_lower(d) .lt. 1.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               endif
            endif

            touches_upper_bdry(d) = .false.
            if ( patch_touches_upper_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (x_upper(d) - X(d,s) .lt. 1.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               endif
            endif

         enddo
c
c     Modify the spreading stencil and weights near physical boundaries.
c
         if (touches_lower_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0
               ic_upper(0) = ifirst0+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0+1
               ic_upper(0) = ifirst0+4
            endif
         elseif (touches_upper_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-3
               ic_upper(0) = ilast0
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-4
               ic_upper(0) = ilast0-1
            endif
            do k = 0,3
               w0(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1
               ic_upper(1) = ifirst1+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1+1
               ic_upper(1) = ifirst1+4
            endif
         elseif (touches_upper_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-3
               ic_upper(1) = ilast1
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-4
               ic_upper(1) = ilast1-1
            endif
            do k = 0,3
               w1(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2
               ic_upper(2) = ifirst2+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2+1
               ic_upper(2) = ifirst2+4
            endif
         elseif (touches_upper_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-3
               ic_upper(2) = ilast2
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-4
               ic_upper(2) = ilast2-1
            endif
            do k = 0,3
               w2(3-k) = f(k)
            enddo
         endif
c
c     Spread V onto u.
c
         do d = 0,depth-1
CDEC$ LOOP COUNT(4)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(4)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(4)
                  do ic0 = ic_lower(0),ic_upper(0)
                     u(ic0,ic1,ic2,d) = u(ic0,ic1,ic2,d)+(
     &                    w0(ic0-ic_lower(0))*
     &                    w1(ic1-ic_lower(1))*
     &                    w2(ic2-ic_lower(2))*
     &                    V(d,s)/(dx(0)*dx(1)*dx(2)))
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Spread V onto u at the positions specified by X using the IB
c     4-point delta function using extended (double-double) precision
c     accumulation on the Cartesian grid.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_4_spread_xp3d(
     &     dx,x_lower,x_upper,depth,
     &     indices,Xshift,nindices,
     &     X,V,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     use_alt_one_sided_delta,
     &     nugc0,nugc1,nugc2,
     &     u)
c
      use ddmodule
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_4_delta
c
c     Input.
c
      INTEGER depth
      INTEGER nindices
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2

      INTEGER indices(0:nindices-1)

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)
      INTEGER use_alt_one_sided_delta(0:NDIM-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:3),w0(0:3),w1(0:3),w2(0:3)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)

      TYPE (DD_REAL), ALLOCATABLE :: u_work(:,:,:,:)
      INTEGER*4 old_cw
c
c     Allocate temporary workspace and copy u to u_work.
c
      ALLOCATE( u_work(CELL3dVECG(ifirst,ilast,nugc),0:depth-1) )
      call f_fpu_fix_start(old_cw)
      do d = 0,depth-1
         do ic2 = ifirst2-nugc2,ilast2+nugc2
            do ic1 = ifirst1-nugc1,ilast1+nugc1
               do ic0 = ifirst0-nugc0,ilast0+nugc0
                  u_work(ic0,ic1,ic2,d) = ddreal(u(ic0,ic1,ic2,d))
               enddo
            enddo
         enddo
      enddo
      call f_fpu_fix_end(old_cw)
c
c     Use the IB 4-point delta function to spread V onto u.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard spreading stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+1
            else
               ic_lower(d) = ic_center(d)-1
               ic_upper(d) = ic_center(d)+2
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard spreading weights.
c
CDEC$ LOOP COUNT(4)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_4_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(4)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_4_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(4)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_4_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special spreading weights are needed to handle
c     physical boundary conditions.
c
         do d = 0,NDIM-1

            touches_lower_bdry(d) = .false.
            if ( patch_touches_lower_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (X(d,s) - x_lower(d) .lt. 1.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
                  touches_lower_bdry(d) = .true.
               endif
            endif

            touches_upper_bdry(d) = .false.
            if ( patch_touches_upper_physical_bdry(d).eq.1 ) then
               if ( (use_alt_one_sided_delta(d).eq.0).and.
     &              (x_upper(d) - X(d,s) .lt. 1.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               elseif ( (use_alt_one_sided_delta(d).eq.1).and.
     &                 (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
                  touches_upper_bdry(d) = .true.
               endif
            endif

         enddo
c
c     Modify the spreading stencil and weights near physical boundaries.
c
         if (touches_lower_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0
               ic_upper(0) = ifirst0+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w0,(X(0,s)-x_lower(0))/dx(0))
               ic_lower(0) = ifirst0+1
               ic_upper(0) = ifirst0+4
            endif
         elseif (touches_upper_bdry(0)) then
            if ( use_alt_one_sided_delta(0).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-3
               ic_upper(0) = ilast0
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(0)-X(0,s))/dx(0))
               ic_lower(0) = ilast0-4
               ic_upper(0) = ilast0-1
            endif
            do k = 0,3
               w0(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1
               ic_upper(1) = ifirst1+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w1,(X(1,s)-x_lower(1))/dx(1))
               ic_lower(1) = ifirst1+1
               ic_upper(1) = ifirst1+4
            endif
         elseif (touches_upper_bdry(1)) then
            if ( use_alt_one_sided_delta(1).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-3
               ic_upper(1) = ilast1
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(1)-X(1,s))/dx(1))
               ic_lower(1) = ilast1-4
               ic_upper(1) = ilast1-1
            endif
            do k = 0,3
               w1(3-k) = f(k)
            enddo
         endif

         if (touches_lower_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2
               ic_upper(2) = ifirst2+3
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              w2,(X(2,s)-x_lower(2))/dx(2))
               ic_lower(2) = ifirst2+1
               ic_upper(2) = ifirst2+4
            endif
         elseif (touches_upper_bdry(2)) then
            if ( use_alt_one_sided_delta(2).eq.0 ) then
               call lagrangian_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-3
               ic_upper(2) = ilast2
            else
               call lagrangian_alt_one_sided_ib_4_delta(
     &              f,(x_upper(2)-X(2,s))/dx(2))
               ic_lower(2) = ilast2-4
               ic_upper(2) = ilast2-1
            endif
            do k = 0,3
               w2(3-k) = f(k)
            enddo
         endif
c
c     Spread V onto u.
c
         call f_fpu_fix_start(old_cw)
         do d = 0,depth-1
CDEC$ LOOP COUNT(4)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(4)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(4)
                  do ic0 = ic_lower(0),ic_upper(0)
                     u_work(ic0,ic1,ic2,d) = u_work(ic0,ic1,ic2,d)+(
     &                    w0(ic0-ic_lower(0))*
     &                    w1(ic1-ic_lower(1))*
     &                    w2(ic2-ic_lower(2))*
     &                    V(d,s)/(dx(0)*dx(1)*dx(2)))
                  enddo
               enddo
            enddo
         enddo
         call f_fpu_fix_end(old_cw)
      enddo
c
c     Copy u_work to u and deallocate temporary workspace.
c
      call f_fpu_fix_start(old_cw)
      do d = 0,depth-1
         do ic2 = ifirst2-nugc2,ilast2+nugc2
            do ic1 = ifirst1-nugc1,ilast1+nugc1
               do ic0 = ifirst0-nugc0,ilast0+nugc0
                  u(ic0,ic1,ic2,d) = dble(u_work(ic0,ic1,ic2,d))
               enddo
            enddo
         enddo
      enddo
      call f_fpu_fix_end(old_cw)
      DEALLOCATE( u_work )
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Interpolate u onto V at the positions specified by X using the IB
c     6-point delta function.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_6_interp3d(
     &     dx,x_lower,x_upper,depth,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     nugc0,nugc1,nugc2,
     &     u,
     &     indices,Xshift,nindices,
     &     X,V)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_6_delta
c
c     Input.
c
      INTEGER depth
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2
      INTEGER nindices

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)

      INTEGER indices(0:nindices-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:5),w0(0:5),w1(0:5),w2(0:5)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 6-point delta function to interpolate u onto V.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard interpolation stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-3
               ic_upper(d) = ic_center(d)+2
            else
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+3
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard interpolation weights.
c
CDEC$ LOOP COUNT(6)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_6_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(6)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_6_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(6)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_6_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special interpolation weights are needed to
c     handle physical boundary conditions.
c
         do d = 0,NDIM-1
            if ( (patch_touches_lower_physical_bdry(d).eq.1).and.
     &           (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
               touches_lower_bdry(d) = .true.
            else
               touches_lower_bdry(d) = .false.
            endif
            if ( (patch_touches_upper_physical_bdry(d).eq.1).and.
     &           (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
               touches_upper_bdry(d) = .true.
            else
               touches_upper_bdry(d) = .false.
            endif
         enddo
c
c     Modify the interpolation stencil and weights near physical
c     boundaries.
c
         if (touches_lower_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w0,(X(0,s)-x_lower(0))/dx(0))
            ic_lower(0) = ifirst0
            ic_upper(0) = ifirst0+5
         elseif (touches_upper_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(0)-X(0,s))/dx(0))
            do k = 0,5
               w0(5-k) = f(k)
            enddo
            ic_lower(0) = ilast0-5
            ic_upper(0) = ilast0
         endif

         if (touches_lower_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w1,(X(1,s)-x_lower(1))/dx(1))
            ic_lower(1) = ifirst1
            ic_upper(1) = ifirst1+5
         elseif (touches_upper_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(1)-X(1,s))/dx(1))
            do k = 0,5
               w1(5-k) = f(k)
            enddo
            ic_lower(1) = ilast1-5
            ic_upper(1) = ilast1
         endif

         if (touches_lower_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w2,(X(2,s)-x_lower(2))/dx(2))
            ic_lower(2) = ifirst2
            ic_upper(2) = ifirst2+5
         elseif (touches_upper_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(2)-X(2,s))/dx(2))
            do k = 0,5
               w2(5-k) = f(k)
            enddo
            ic_lower(2) = ilast2-5
            ic_upper(2) = ilast2
         endif
c
c     Interpolate u onto V.
c
         do d = 0,depth-1
            V(d,s) = 0.d0
CDEC$ LOOP COUNT(6)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(6)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(6)
CDEC$ NOVECTOR
                  do ic0 = ic_lower(0),ic_upper(0)
                     V(d,s) = V(d,s)
     &                    +w0(ic0-ic_lower(0))
     &                    *w1(ic1-ic_lower(1))
     &                    *w2(ic2-ic_lower(2))
     &                    *u(ic0,ic1,ic2,d)
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Spread V onto u at the positions specified by X using the IB
c     6-point delta function using standard (double) precision
c     accumulation on the Cartesian grid.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_6_spread3d(
     &     dx,x_lower,x_upper,depth,
     &     indices,Xshift,nindices,
     &     X,V,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     nugc0,nugc1,nugc2,
     &     u)
c
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_6_delta
c
c     Input.
c
      INTEGER depth
      INTEGER nindices
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2

      INTEGER indices(0:nindices-1)

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:5),w0(0:5),w1(0:5),w2(0:5)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)
c
c     Use the IB 6-point delta function to spread V onto u.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard spreading stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-3
               ic_upper(d) = ic_center(d)+2
            else
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+3
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard spreading weights.
c
CDEC$ LOOP COUNT(6)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_6_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(6)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_6_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(6)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_6_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special spreading weights are needed to handle
c     physical boundary conditions.
c
         do d = 0,NDIM-1
            if ( (patch_touches_lower_physical_bdry(d).eq.1).and.
     &           (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
               touches_lower_bdry(d) = .true.
            else
               touches_lower_bdry(d) = .false.
            endif
            if ( (patch_touches_upper_physical_bdry(d).eq.1).and.
     &           (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
               touches_upper_bdry(d) = .true.
            else
               touches_upper_bdry(d) = .false.
            endif
         enddo
c
c     Modify the spreading stencil and weights near physical boundaries.
c
         if (touches_lower_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w0,(X(0,s)-x_lower(0))/dx(0))
            ic_lower(0) = ifirst0
            ic_upper(0) = ifirst0+5
         elseif (touches_upper_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(0)-X(0,s))/dx(0))
            do k = 0,5
               w0(5-k) = f(k)
            enddo
            ic_lower(0) = ilast0-5
            ic_upper(0) = ilast0
         endif

         if (touches_lower_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w1,(X(1,s)-x_lower(1))/dx(1))
            ic_lower(1) = ifirst1
            ic_upper(1) = ifirst1+5
         elseif (touches_upper_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(1)-X(1,s))/dx(1))
            do k = 0,5
               w1(5-k) = f(k)
            enddo
            ic_lower(1) = ilast1-5
            ic_upper(1) = ilast1
         endif

         if (touches_lower_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w2,(X(2,s)-x_lower(2))/dx(2))
            ic_lower(2) = ifirst2
            ic_upper(2) = ifirst2+5
         elseif (touches_upper_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(2)-X(2,s))/dx(2))
            do k = 0,5
               w2(5-k) = f(k)
            enddo
            ic_lower(2) = ilast2-5
            ic_upper(2) = ilast2
         endif
c
c     Spread V onto u.
c
         do d = 0,depth-1
CDEC$ LOOP COUNT(6)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(6)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(6)
CDEC$ NOVECTOR
                  do ic0 = ic_lower(0),ic_upper(0)
                     u(ic0,ic1,ic2,d) = u(ic0,ic1,ic2,d)+(
     &                    w0(ic0-ic_lower(0))*
     &                    w1(ic1-ic_lower(1))*
     &                    w2(ic2-ic_lower(2))*
     &                    V(d,s)/(dx(0)*dx(1)*dx(2)))
                  enddo
               enddo
            enddo
         enddo
      enddo
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Spread V onto u at the positions specified by X using the IB
c     6-point delta function using extended (double-double) precision
c     accumulation on the Cartesian grid.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
      subroutine lagrangian_ib_6_spread_xp3d(
     &     dx,x_lower,x_upper,depth,
     &     indices,Xshift,nindices,
     &     X,V,
     &     ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2,
     &     patch_touches_lower_physical_bdry,
     &     patch_touches_upper_physical_bdry,
     &     nugc0,nugc1,nugc2,
     &     u)
c
      use ddmodule
      implicit none
c
c     Functions.
c
      EXTERNAL lagrangian_floor
      INTEGER lagrangian_floor
      REAL lagrangian_ib_6_delta
c
c     Input.
c
      INTEGER depth
      INTEGER nindices
      INTEGER ifirst0,ilast0,ifirst1,ilast1,ifirst2,ilast2
      INTEGER nugc0,nugc1,nugc2

      INTEGER indices(0:nindices-1)

      INTEGER patch_touches_lower_physical_bdry(0:NDIM-1)
      INTEGER patch_touches_upper_physical_bdry(0:NDIM-1)

      REAL Xshift(0:NDIM-1,0:nindices-1)

      REAL dx(0:NDIM-1),x_lower(0:NDIM-1),x_upper(0:NDIM-1)
      REAL u(CELL3dVECG(ifirst,ilast,nugc),0:depth-1)
      REAL X(0:NDIM-1,0:*)
c
c     Input/Output.
c
      REAL V(0:depth-1,0:*)
c
c     Local variables.
c
      INTEGER ic0,ic1,ic2
      INTEGER ic_center(0:NDIM-1),ic_lower(0:NDIM-1),ic_upper(0:NDIM-1)
      INTEGER d,k,l,s

      REAL X_cell(0:NDIM-1),f(0:5),w0(0:5),w1(0:5),w2(0:5)

      LOGICAL touches_lower_bdry(0:NDIM-1)
      LOGICAL touches_upper_bdry(0:NDIM-1)

      TYPE (DD_REAL), ALLOCATABLE :: u_work(:,:,:,:)
      INTEGER*4 old_cw
c
c     Allocate temporary workspace and copy u to u_work.
c
      ALLOCATE( u_work(CELL3dVECG(ifirst,ilast,nugc),0:depth-1) )
      call f_fpu_fix_start(old_cw)
      do d = 0,depth-1
         do ic2 = ifirst2-nugc2,ilast2+nugc2
            do ic1 = ifirst1-nugc1,ilast1+nugc1
               do ic0 = ifirst0-nugc0,ilast0+nugc0
                  u_work(ic0,ic1,ic2,d) = ddreal(u(ic0,ic1,ic2,d))
               enddo
            enddo
         enddo
      enddo
      call f_fpu_fix_end(old_cw)
c
c     Use the IB 6-point delta function to spread V onto u.
c
      do l = 0,nindices-1
         s = indices(l)
c
c     Determine the Cartesian cell in which X(s) is located.
c
         ic_center(0) =
     &        lagrangian_floor((X(0,s)+Xshift(0,l)-x_lower(0))/dx(0))
     &        + ifirst0
         ic_center(1) =
     &        lagrangian_floor((X(1,s)+Xshift(1,l)-x_lower(1))/dx(1))
     &        + ifirst1
         ic_center(2) =
     &        lagrangian_floor((X(2,s)+Xshift(2,l)-x_lower(2))/dx(2))
     &        + ifirst2

         X_cell(0) = x_lower(0)+(dble(ic_center(0)-ifirst0)+0.5d0)*dx(0)
         X_cell(1) = x_lower(1)+(dble(ic_center(1)-ifirst1)+0.5d0)*dx(1)
         X_cell(2) = x_lower(2)+(dble(ic_center(2)-ifirst2)+0.5d0)*dx(2)
c
c     Determine the standard spreading stencil corresponding to the
c     position of X(s) within the cell.
c
         do d = 0,NDIM-1
            if ( X(d,s).lt.X_cell(d) ) then
               ic_lower(d) = ic_center(d)-3
               ic_upper(d) = ic_center(d)+2
            else
               ic_lower(d) = ic_center(d)-2
               ic_upper(d) = ic_center(d)+3
            endif
         enddo

         ic_lower(0) = max(ic_lower(0),ifirst0-nugc0)
         ic_upper(0) = min(ic_upper(0),ilast0 +nugc0)

         ic_lower(1) = max(ic_lower(1),ifirst1-nugc1)
         ic_upper(1) = min(ic_upper(1),ilast1 +nugc1)

         ic_lower(2) = max(ic_lower(2),ifirst2-nugc2)
         ic_upper(2) = min(ic_upper(2),ilast2 +nugc2)
c
c     Compute the standard spreading weights.
c
CDEC$ LOOP COUNT(6)
         do ic0 = ic_lower(0),ic_upper(0)
            X_cell(0) = x_lower(0)+(dble(ic0-ifirst0)+0.5d0)*dx(0)
            w0(ic0-ic_lower(0)) =
     &           lagrangian_ib_6_delta(
     &           (X(0,s)+Xshift(0,l)-X_cell(0))/dx(0))
         enddo
CDEC$ LOOP COUNT(6)
         do ic1 = ic_lower(1),ic_upper(1)
            X_cell(1) = x_lower(1)+(dble(ic1-ifirst1)+0.5d0)*dx(1)
            w1(ic1-ic_lower(1)) =
     &           lagrangian_ib_6_delta(
     &           (X(1,s)+Xshift(1,l)-X_cell(1))/dx(1))
         enddo
CDEC$ LOOP COUNT(6)
         do ic2 = ic_lower(2),ic_upper(2)
            X_cell(2) = x_lower(2)+(dble(ic2-ifirst2)+0.5d0)*dx(2)
            w2(ic2-ic_lower(2)) =
     &           lagrangian_ib_6_delta(
     &           (X(2,s)+Xshift(2,l)-X_cell(2))/dx(2))
         enddo
c
c     Determine whether special spreading weights are needed to handle
c     physical boundary conditions.
c
         do d = 0,NDIM-1
            if ( (patch_touches_lower_physical_bdry(d).eq.1).and.
     &           (X(d,s) - x_lower(d) .lt. 2.5d0*dx(d)) ) then
               touches_lower_bdry(d) = .true.
            else
               touches_lower_bdry(d) = .false.
            endif
            if ( (patch_touches_upper_physical_bdry(d).eq.1).and.
     &           (x_upper(d) - X(d,s) .lt. 2.5d0*dx(d)) ) then
               touches_upper_bdry(d) = .true.
            else
               touches_upper_bdry(d) = .false.
            endif
         enddo
c
c     Modify the spreading stencil and weights near physical boundaries.
c
         if (touches_lower_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w0,(X(0,s)-x_lower(0))/dx(0))
            ic_lower(0) = ifirst0
            ic_upper(0) = ifirst0+5
         elseif (touches_upper_bdry(0)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(0)-X(0,s))/dx(0))
            do k = 0,5
               w0(5-k) = f(k)
            enddo
            ic_lower(0) = ilast0-5
            ic_upper(0) = ilast0
         endif

         if (touches_lower_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w1,(X(1,s)-x_lower(1))/dx(1))
            ic_lower(1) = ifirst1
            ic_upper(1) = ifirst1+5
         elseif (touches_upper_bdry(1)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(1)-X(1,s))/dx(1))
            do k = 0,5
               w1(5-k) = f(k)
            enddo
            ic_lower(1) = ilast1-5
            ic_upper(1) = ilast1
         endif

         if (touches_lower_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           w2,(X(2,s)-x_lower(2))/dx(2))
            ic_lower(2) = ifirst2
            ic_upper(2) = ifirst2+5
         elseif (touches_upper_bdry(2)) then
            call lagrangian_one_sided_ib_6_delta(
     &           f,(x_upper(2)-X(2,s))/dx(2))
            do k = 0,5
               w2(5-k) = f(k)
            enddo
            ic_lower(2) = ilast2-5
            ic_upper(2) = ilast2
         endif
c
c     Spread V onto u.
c
         do d = 0,depth-1
CDEC$ LOOP COUNT(6)
            do ic2 = ic_lower(2),ic_upper(2)
CDEC$ LOOP COUNT(6)
               do ic1 = ic_lower(1),ic_upper(1)
CDEC$ LOOP COUNT(6)
CDEC$ NOVECTOR
                  do ic0 = ic_lower(0),ic_upper(0)
                     u_work(ic0,ic1,ic2,d) = u_work(ic0,ic1,ic2,d)+(
     &                    w0(ic0-ic_lower(0))*
     &                    w1(ic1-ic_lower(1))*
     &                    w2(ic2-ic_lower(2))*
     &                    V(d,s)/(dx(0)*dx(1)*dx(2)))
                  enddo
               enddo
            enddo
         enddo
      enddo
c
c     Copy u_work to u and deallocate temporary workspace.
c
      call f_fpu_fix_start(old_cw)
      do d = 0,depth-1
         do ic2 = ifirst2-nugc2,ilast2+nugc2
            do ic1 = ifirst1-nugc1,ilast1+nugc1
               do ic0 = ifirst0-nugc0,ilast0+nugc0
                  u(ic0,ic1,ic2,d) = dble(u_work(ic0,ic1,ic2,d))
               enddo
            enddo
         enddo
      enddo
      call f_fpu_fix_end(old_cw)
      DEALLOCATE( u_work )
c
      return
      end
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc